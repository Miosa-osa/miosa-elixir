defmodule Miosa.WebSocket do
  @moduledoc false

  use GenServer

  @default_connect_timeout 5_000
  @default_max_message_size 1_048_576

  defstruct [:conn, :ref, :websocket, :owner, :owner_monitor, :max_message_size]

  @type event ::
          {:frame, {:text | :binary, binary()}}
          | {:closed, non_neg_integer() | nil, binary() | nil}
          | {:error, term()}

  @spec connect(String.t(), keyword()) :: {:ok, pid()} | {:error, term()}
  def connect(url, opts \\ []) when is_binary(url) do
    opts = Keyword.put_new(opts, :owner, self())
    GenServer.start(__MODULE__, {url, opts})
  end

  @spec send_frame(pid(), Mint.WebSocket.frame() | Mint.WebSocket.shorthand_frame()) ::
          :ok | {:error, term()}
  def send_frame(pid, frame) when is_pid(pid) do
    GenServer.call(pid, {:send, frame})
  catch
    :exit, _ -> {:error, :closed}
  end

  @spec close(pid()) :: :ok
  def close(pid) when is_pid(pid) do
    GenServer.call(pid, :close)
  catch
    :exit, _ -> :ok
  end

  @impl true
  def init({url, opts}) do
    owner = Keyword.get(opts, :owner, self())
    timeout = Keyword.get(opts, :connect_timeout, @default_connect_timeout)
    max_message_size = Keyword.get(opts, :max_message_size, @default_max_message_size)

    with :ok <- validate_max_message_size(max_message_size),
         {:ok, conn, ref, websocket, early_data} <- open(url, opts, timeout) do
      state = %__MODULE__{
        conn: conn,
        ref: ref,
        websocket: websocket,
        owner: owner,
        owner_monitor: Process.monitor(owner),
        max_message_size: max_message_size
      }

      Enum.each(early_data, &send(self(), {:early_websocket_data, &1}))
      {:ok, state}
    else
      {:error, reason} -> {:stop, reason}
    end
  end

  @impl true
  def handle_call({:send, frame}, _from, state) do
    case write_frame(state, frame) do
      {:ok, state} -> {:reply, :ok, state}
      {:error, reason, state} -> stop_with_error(reason, state, {:reply, {:error, reason}})
    end
  end

  def handle_call(:close, _from, state) do
    state = best_effort_write(state, {:close, 1_000, ""})
    {:stop, :normal, :ok, close_connection(state)}
  end

  @impl true
  def handle_info({:early_websocket_data, data}, state) do
    case decode_data(data, state) do
      {:ok, state} -> {:noreply, state}
      terminal -> terminal
    end
  end

  def handle_info(
        {:DOWN, monitor, :process, owner, _reason},
        %{owner_monitor: monitor, owner: owner} = state
      ) do
    {:stop, :normal, close_connection(state)}
  end

  def handle_info(message, state) do
    case Mint.WebSocket.stream(state.conn, message) do
      {:ok, conn, responses} ->
        process_responses(responses, %{state | conn: conn})

      {:error, conn, reason, responses} ->
        state = %{state | conn: conn}

        case process_responses(responses, state) do
          {:noreply, state} -> stop_with_error(reason, state, :noreply)
          terminal -> terminal
        end

      :unknown ->
        {:noreply, state}
    end
  end

  @impl true
  def terminate(_reason, state) do
    close_connection(state)
    :ok
  end

  defp open(url, opts, timeout) do
    with {:ok, uri, http_scheme, ws_scheme, port} <- parse_url(url),
         {:ok, conn} <- connect_http(http_scheme, uri.host, port, timeout) do
      case Mint.WebSocket.upgrade(
             ws_scheme,
             conn,
             request_target(uri),
             upgrade_headers(opts)
           ) do
        {:ok, conn, ref} ->
          finish_upgrade(conn, ref, Keyword.get(opts, :subprotocol), timeout)

        {:error, conn, reason} ->
          Mint.HTTP.close(conn)
          {:error, reason}
      end
    end
  end

  defp parse_url(url) do
    uri = URI.parse(url)

    case {uri.scheme, uri.host} do
      {"ws", host} when is_binary(host) -> {:ok, uri, :http, :ws, uri.port || 80}
      {"wss", host} when is_binary(host) -> {:ok, uri, :https, :wss, uri.port || 443}
      {scheme, _host} -> {:error, {:invalid_websocket_url, scheme}}
    end
  end

  defp connect_http(:http, host, port, timeout) do
    Mint.HTTP.connect(:http, host, port,
      protocols: [:http1],
      transport_opts: [timeout: timeout]
    )
  end

  defp connect_http(:https, host, port, timeout) do
    Mint.HTTP.connect(:https, host, port,
      protocols: [:http1],
      transport_opts: [
        timeout: timeout,
        verify: :verify_peer,
        cacerts: :public_key.cacerts_get(),
        server_name_indication: String.to_charlist(host),
        customize_hostname_check: [match_fun: :public_key.pkix_verify_hostname_match_fun(:https)],
        versions: [:"tlsv1.2", :"tlsv1.3"]
      ]
    )
  end

  defp finish_upgrade(conn, ref, subprotocol, timeout) do
    deadline = System.monotonic_time(:millisecond) + timeout
    await_upgrade(conn, ref, nil, [], subprotocol, deadline)
  end

  defp await_upgrade(conn, ref, status, headers, subprotocol, deadline) do
    timeout = max(deadline - System.monotonic_time(:millisecond), 0)

    receive do
      message ->
        case Mint.WebSocket.stream(conn, message) do
          {:ok, conn, responses} ->
            case collect_upgrade(responses, ref, status, headers) do
              {:continue, status, headers} ->
                await_upgrade(conn, ref, status, headers, subprotocol, deadline)

              {:done, status, headers, early_data} ->
                establish_websocket(conn, ref, status, headers, subprotocol, early_data)
            end

          {:error, conn, reason, _responses} ->
            Mint.HTTP.close(conn)
            {:error, reason}

          :unknown ->
            await_upgrade(conn, ref, status, headers, subprotocol, deadline)
        end
    after
      timeout ->
        Mint.HTTP.close(conn)
        {:error, :upgrade_timeout}
    end
  end

  defp collect_upgrade(responses, ref, status, headers) do
    {status, headers, done?, early_data} =
      Enum.reduce(responses, {status, headers, false, []}, fn
        {:status, ^ref, value}, {_status, headers, done?, early_data} ->
          {value, headers, done?, early_data}

        {:headers, ^ref, value}, {status, headers, done?, early_data} ->
          {status, headers ++ value, done?, early_data}

        {:done, ^ref}, {status, headers, _done?, early_data} ->
          {status, headers, true, early_data}

        {:data, ^ref, data}, {status, headers, done?, early_data} ->
          {status, headers, done?, [data | early_data]}

        _response, acc ->
          acc
      end)

    if done? do
      {:done, status, headers, Enum.reverse(early_data)}
    else
      {:continue, status, headers}
    end
  end

  defp establish_websocket(conn, ref, status, headers, subprotocol, early_data) do
    with :ok <- validate_subprotocol(headers, subprotocol),
         {:ok, conn, websocket} <- Mint.WebSocket.new(conn, ref, status, headers) do
      {:ok, conn, ref, websocket, early_data}
    else
      {:error, conn, reason} ->
        Mint.HTTP.close(conn)
        {:error, reason}

      {:error, reason} ->
        Mint.HTTP.close(conn)
        {:error, reason}
    end
  end

  defp validate_subprotocol(headers, expected) do
    selected =
      for {name, value} <- headers,
          String.downcase(name) == "sec-websocket-protocol",
          do: String.trim(value)

    expected_selection = if expected, do: [expected], else: []

    if selected == expected_selection,
      do: :ok,
      else: {:error, {:subprotocol_mismatch, selected}}
  end

  defp request_target(%URI{path: path, query: query}) do
    path = if path in [nil, ""], do: "/", else: path
    if query, do: path <> "?" <> query, else: path
  end

  defp upgrade_headers(opts) do
    headers = Keyword.get(opts, :headers, [])

    case Keyword.get(opts, :subprotocol) do
      nil ->
        headers

      subprotocol ->
        headers =
          Enum.reject(headers, fn {name, _value} ->
            String.downcase(to_string(name)) == "sec-websocket-protocol"
          end)

        [{"sec-websocket-protocol", subprotocol} | headers]
    end
  end

  defp process_responses(responses, state) do
    Enum.reduce_while(responses, {:noreply, state}, fn
      {:data, ref, data}, {:noreply, %{ref: ref} = state} ->
        case decode_data(data, state) do
          {:ok, state} -> {:cont, {:noreply, state}}
          terminal -> {:halt, terminal}
        end

      _response, acc ->
        {:cont, acc}
    end)
  end

  defp decode_data(data, state) do
    case Mint.WebSocket.decode(state.websocket, data) do
      {:ok, websocket, frames} ->
        process_frames(frames, %{state | websocket: websocket})

      {:error, websocket, reason} ->
        protocol_error(reason, %{state | websocket: websocket})
    end
  end

  defp process_frames(frames, state) do
    Enum.reduce_while(frames, {:ok, state}, fn frame, {:ok, state} ->
      case process_frame(frame, state) do
        {:ok, state} -> {:cont, {:ok, state}}
        terminal -> {:halt, terminal}
      end
    end)
    |> case do
      {:ok, state} -> {:ok, state}
      terminal -> terminal
    end
  end

  defp process_frame({kind, data} = frame, state) when kind in [:text, :binary] do
    if byte_size(data) <= state.max_message_size do
      notify(state, {:frame, frame})
      {:ok, state}
    else
      state = best_effort_write(state, {:close, 1_009, "message too large"})
      notify(state, {:error, :message_too_large})
      {:stop, :normal, close_connection(state)}
    end
  end

  defp process_frame({:ping, data}, state) do
    case write_frame(state, {:pong, data}) do
      {:ok, state} -> {:ok, state}
      {:error, reason, state} -> stop_with_error(reason, state, :noreply)
    end
  end

  defp process_frame({:pong, _data}, state), do: {:ok, state}

  defp process_frame({:close, code, reason}, state) do
    state = best_effort_write(state, {:close, code || 1_000, reason || ""})
    notify(state, {:closed, code, reason})
    {:stop, :normal, close_connection(state)}
  end

  defp process_frame({:error, reason}, state), do: protocol_error(reason, state)

  defp protocol_error(reason, state) do
    state = best_effort_write(state, {:close, 1_002, "protocol error"})
    notify(state, {:error, reason})
    {:stop, :normal, close_connection(state)}
  end

  defp write_frame(state, frame) do
    with {:ok, websocket, data} <- Mint.WebSocket.encode(state.websocket, frame),
         {:ok, conn} <- Mint.WebSocket.stream_request_body(state.conn, state.ref, data) do
      {:ok, %{state | conn: conn, websocket: websocket}}
    else
      {:error, websocket, reason} when is_struct(websocket, Mint.WebSocket) ->
        {:error, reason, %{state | websocket: websocket}}

      {:error, conn, reason} ->
        {:error, reason, %{state | conn: conn}}
    end
  end

  defp best_effort_write(state, frame) do
    case write_frame(state, frame) do
      {:ok, state} -> state
      {:error, _reason, state} -> state
    end
  end

  defp stop_with_error(reason, state, reply) do
    notify(state, {:error, reason})
    state = close_connection(state)

    case reply do
      :noreply -> {:stop, :normal, state}
      {:reply, value} -> {:stop, :normal, value, state}
    end
  end

  defp notify(state, event) do
    send(state.owner, {:miosa_web_socket, self(), event})
  end

  defp close_connection(%{conn: nil} = state), do: state

  defp close_connection(state) do
    Mint.HTTP.close(state.conn)
    %{state | conn: nil}
  end

  defp validate_max_message_size(size) when is_integer(size) and size > 0, do: :ok
  defp validate_max_message_size(size), do: {:error, {:invalid_max_message_size, size}}
end
