defmodule Miosa.Exec.Command do
  @moduledoc """
  A GenServer holding a long-lived interactive command session over WebSocket.

  Obtained via `Miosa.Exec.spawn/3`. Provides stdin/stdout interaction and
  terminal resize for PTY-based commands.

  The GenServer owns the WebSocket connection and shuts it down on
  termination.

  ## Example

      {:ok, cmd} = Miosa.Exec.spawn(client, computer_id, "bash")

      :ok = Miosa.Exec.Command.send_stdin(cmd, "ls -la\\n")
      :ok = Miosa.Exec.Command.resize(cmd, 120, 40)

      # Block until the command exits (or timeout)
      {:ok, exit_code} = Miosa.Exec.Command.await(cmd, 30_000)

  """

  use GenServer
  require Logger

  @default_await_timeout 30_000

  defstruct [
    :client,
    :computer_id,
    :command,
    :websocket_pid,
    :status,
    :exit_code,
    :error_reason,
    :output_buffer,
    :waiters
  ]

  @type t :: pid()

  # ---------------------------------------------------------------------------
  # Client API
  # ---------------------------------------------------------------------------

  @doc """
  Sends data to the command's stdin.

  `data` should be a binary string (may include newlines).
  Returns `:ok` immediately; delivery is async over the WebSocket.
  """
  @spec send_stdin(t(), String.t()) :: :ok | {:error, term()}
  def send_stdin(pid, data) when is_pid(pid) and is_binary(data) do
    GenServer.call(pid, {:send_stdin, data})
  end

  @doc """
  Signals stdin EOF to the command (closes the write half of the WebSocket).
  """
  @spec close_stdin(t()) :: :ok | {:error, term()}
  def close_stdin(pid) when is_pid(pid) do
    GenServer.call(pid, :close_stdin)
  end

  @doc """
  Sends a terminal resize event (SIGWINCH) to the running command.

  Only meaningful for PTY-based commands (those started with `pty: true`).
  """
  @spec resize(t(), pos_integer(), pos_integer()) :: :ok | {:error, term()}
  def resize(pid, cols, rows) when is_pid(pid) and is_integer(cols) and is_integer(rows) do
    GenServer.call(pid, {:resize, cols, rows})
  end

  @doc """
  Blocks until the command exits and returns `{:ok, exit_code}`.

  Returns `{:error, :timeout}` if the command does not exit within `timeout_ms`.
  The GenServer process is stopped after `await/2` returns.
  """
  @spec await(t(), pos_integer()) :: {:ok, integer()} | {:error, :timeout | term()}
  def await(pid, timeout_ms \\ @default_await_timeout) when is_pid(pid) do
    try do
      GenServer.call(pid, {:await, timeout_ms}, :infinity)
    catch
      :exit, reason -> {:error, reason}
    end
  end

  # ---------------------------------------------------------------------------
  # GenServer lifecycle
  # ---------------------------------------------------------------------------

  @doc false
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    client = Keyword.fetch!(opts, :client)
    computer_id = Keyword.fetch!(opts, :computer_id)
    command = Keyword.fetch!(opts, :command)
    pty = Keyword.get(opts, :pty, false)

    state = %__MODULE__{
      client: client,
      computer_id: computer_id,
      command: command,
      status: :connecting,
      exit_code: nil,
      output_buffer: [],
      waiters: %{}
    }

    # Connect asynchronously so init does not block the caller.
    send(self(), {:connect, pty})
    {:ok, state}
  end

  @impl true
  def handle_info({:connect, pty}, state) do
    %__MODULE__{client: client, computer_id: cid, command: command} = state

    ws_url = build_ws_url(client, cid, command, pty)

    case Miosa.WebSocket.connect(ws_url,
           owner: self(),
           headers: [{"authorization", "Bearer #{client.api_key}"}],
           connect_timeout: client.timeout
         ) do
      {:ok, websocket_pid} ->
        {:noreply, %{state | websocket_pid: websocket_pid, status: :running}}

      {:error, reason} ->
        Logger.error("[Miosa.Exec.Command] WebSocket connect failed: #{inspect(reason)}")
        {:stop, {:ws_connect_failed, reason}, state}
    end
  end

  def handle_info(
        {:miosa_web_socket, websocket_pid, {:frame, {:text, data}}},
        %{
          websocket_pid: websocket_pid
        } = state
      ) do
    new_buffer = [data | state.output_buffer]
    {:noreply, %{state | output_buffer: new_buffer}}
  end

  def handle_info(
        {:miosa_web_socket, websocket_pid, {:frame, {:binary, data}}},
        %{
          websocket_pid: websocket_pid
        } = state
      ) do
    new_buffer = [data | state.output_buffer]
    {:noreply, %{state | output_buffer: new_buffer}}
  end

  def handle_info(
        {:miosa_web_socket, websocket_pid, {:closed, code, _reason}},
        %{
          websocket_pid: websocket_pid
        } = state
      ) do
    exit_code = if code in 1000..1999, do: code - 1000, else: 0
    new_state = %{state | status: :done, exit_code: exit_code}
    reply_waiters(new_state)

    if map_size(state.waiters) == 0 do
      {:noreply, new_state}
    else
      {:stop, :normal, new_state}
    end
  end

  def handle_info(
        {:miosa_web_socket, websocket_pid, {:error, reason}},
        %{
          websocket_pid: websocket_pid
        } = state
      ) do
    Logger.warning("[Miosa.Exec.Command] WebSocket connection failed: #{inspect(reason)}")
    new_state = %{state | status: :error, exit_code: -1, error_reason: reason}
    reply_waiters(new_state, {:error, reason})

    if map_size(state.waiters) == 0 do
      {:noreply, new_state}
    else
      {:stop, :normal, new_state}
    end
  end

  def handle_info({:await_timeout, token}, state) do
    case Map.pop(state.waiters, token) do
      {nil, _waiters} ->
        {:noreply, state}

      {{from, _timer}, waiters} ->
        GenServer.reply(from, {:error, :timeout})
        reply_waiters(%{state | waiters: waiters}, {:error, :timeout})
        {:stop, :normal, %{state | waiters: %{}}}
    end
  end

  def handle_info(_msg, state), do: {:noreply, state}

  @impl true
  def handle_call({:send_stdin, data}, _from, %{status: :running} = state) do
    {:reply, Miosa.WebSocket.send_frame(state.websocket_pid, {:text, data}), state}
  end

  def handle_call({:send_stdin, _data}, _from, state) do
    {:reply, {:error, :not_running}, state}
  end

  def handle_call(:close_stdin, _from, %{status: :running} = state) do
    {:reply, Miosa.WebSocket.send_frame(state.websocket_pid, :close), state}
  end

  def handle_call(:close_stdin, _from, state) do
    {:reply, {:error, :not_running}, state}
  end

  def handle_call({:resize, cols, rows}, _from, %{status: :running} = state) do
    payload = Jason.encode!(%{"type" => "resize", "cols" => cols, "rows" => rows})
    {:reply, Miosa.WebSocket.send_frame(state.websocket_pid, {:text, payload}), state}
  end

  def handle_call({:resize, _cols, _rows}, _from, state) do
    {:reply, {:error, :not_running}, state}
  end

  def handle_call({:await, _timeout_ms}, _from, %{status: :done} = state) do
    {:stop, :normal, {:ok, state.exit_code || 0}, state}
  end

  def handle_call({:await, _timeout_ms}, _from, %{status: :error} = state) do
    {:stop, :normal, {:error, state.error_reason}, state}
  end

  def handle_call({:await, timeout_ms}, from, state)
      when is_integer(timeout_ms) and timeout_ms >= 0 do
    token = make_ref()
    timer = Process.send_after(self(), {:await_timeout, token}, timeout_ms)
    {:noreply, %{state | waiters: Map.put(state.waiters, token, {from, timer})}}
  end

  @impl true
  def terminate(_reason, %{websocket_pid: websocket_pid}) when is_pid(websocket_pid) do
    Miosa.WebSocket.close(websocket_pid)
    :ok
  end

  def terminate(_reason, _state), do: :ok

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp reply_waiters(%{waiters: waiters, exit_code: code}, reply \\ nil) do
    Enum.each(waiters, fn {_token, {from, timer}} ->
      Process.cancel_timer(timer)
      GenServer.reply(from, reply || {:ok, code || 0})
    end)
  end

  defp build_ws_url(client, computer_id, command, pty) do
    uri = URI.parse(client.base_url)
    scheme = if uri.scheme == "https", do: "wss", else: "ws"
    base_path = String.trim_trailing(uri.path || "", "/")
    path = "#{base_path}/computers/#{encode_path_segment(computer_id)}/exec/ws"

    command_query = URI.encode_query(%{"command" => command})
    command_query = if pty, do: command_query <> "&pty=true", else: command_query
    query = Enum.reject([uri.query, command_query], &is_nil/1) |> Enum.join("&")

    %{uri | scheme: scheme, path: path, query: query, fragment: nil}
    |> URI.to_string()
  end

  defp encode_path_segment(value), do: URI.encode(value, &URI.char_unreserved?/1)
end
