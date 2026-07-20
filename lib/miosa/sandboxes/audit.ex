defmodule Miosa.Sandboxes.Audit do
  @moduledoc """
  Sandbox-bound view of `Miosa.Audit`.

  `list/3` pre-scopes `resource_id` and `resource_type="sandbox"`.

  `tail/2` opens a live WebSocket connection to the per-sandbox stream
  endpoint (`/api/v1/egress/audit/resource/:resource_id`). The subprotocol is
  `miosa-egress-audit-v1` and the API key is passed via `?token=` query
  parameter.

  Falls back to REST long-polling if the WebSocket connection fails.

  ## Usage

      {:ok, sandbox} = Miosa.Sandboxes.create(client, %{name: "my-box"})

      {:ok, events} = Miosa.Sandboxes.Audit.list(sandbox, client)

      # Live WebSocket tail — returns a lazy Stream
      {:ok, stream} = Miosa.Sandboxes.Audit.tail(sandbox, client)
      stream |> Stream.take(5) |> Enum.to_list()

  The `sandbox` argument may be either a `Miosa.Types.Computer.t()` struct or
  a plain binary sandbox ID string.
  """

  alias Miosa.{Audit, Client}

  @resource_type "sandbox"
  @ws_subprotocol "miosa-egress-audit-v1"
  @ws_connect_timeout_ms 5_000

  # ---------------------------------------------------------------------------
  # Query
  # ---------------------------------------------------------------------------

  @doc """
  List audit events for this sandbox.

  Accepts the same optional `filters` map as `Miosa.Audit.list/2`.
  """
  @spec list(map() | String.t(), Client.t(), map()) :: Client.result([map()])
  def list(sandbox_or_id, %Client{} = client, filters \\ %{}) do
    rid = resource_id(sandbox_or_id)

    merged =
      filters
      |> Map.put_new(:resource_id, rid)
      |> Map.put_new(:resource_type, @resource_type)

    Audit.list(client, merged)
  end

  @doc """
  Fetch a single audit event by ID.
  """
  @spec get(map() | String.t(), Client.t(), String.t()) :: Client.result(map())
  def get(_sandbox_or_id, %Client{} = client, event_id) when is_binary(event_id) do
    Audit.get(client, event_id)
  end

  # ---------------------------------------------------------------------------
  # Live tail (WebSocket → REST fallback)
  # ---------------------------------------------------------------------------

  @doc """
  Return `{:ok, stream}` where `stream` is a lazy `Stream` that yields
  decoded audit-event maps in real time.

  Internally opens a WebSocket to `/api/v1/egress/audit/resource/:resource_id`
  using subprotocol
  `miosa-egress-audit-v1`. The API key is passed via `?token=` query string
  so the `Authorization` header is not needed on the upgrade request.

  If the WebSocket handshake fails (e.g. server pre-dates the endpoint),
  falls back transparently to `Miosa.Audit.tail/3` long-polling.

  ## Options (keyword)

    * `:poll_interval_ms` — polling cadence used in the fallback mode.
      Defaults to `2_000`.
  """
  @spec tail(map() | String.t(), Client.t(), keyword()) ::
          {:ok, Enumerable.t()} | {:error, Miosa.Error.t()}
  def tail(sandbox_or_id, %Client{} = client, opts \\ []) do
    rid = resource_id(sandbox_or_id)
    poll_interval_ms = Keyword.get(opts, :poll_interval_ms, 2_000)

    case try_ws_stream(client, rid, poll_interval_ms) do
      {:ok, stream} ->
        {:ok, stream}

      :fallback ->
        {:ok, Audit.tail(client, rid, Keyword.put(opts, :resource_type, @resource_type))}
    end
  end

  # ---------------------------------------------------------------------------
  # Private WebSocket stream
  # ---------------------------------------------------------------------------

  defp try_ws_stream(client, resource_id, _poll_interval_ms) do
    uri = URI.parse(client.base_url)
    scheme = if uri.scheme == "https", do: "wss", else: "ws"
    base_path = String.trim_trailing(uri.path || "/api/v1", "/")
    path = "#{base_path}/egress/audit/resource/#{encode_path_segment(resource_id)}"
    token_query = URI.encode_query(%{"token" => client.api_key})
    query = Enum.reject([uri.query, token_query], &is_nil/1) |> Enum.join("&")
    url = %{uri | scheme: scheme, path: path, query: query, fragment: nil} |> URI.to_string()

    case Miosa.WebSocket.connect(url,
           owner: self(),
           subprotocol: @ws_subprotocol,
           connect_timeout: @ws_connect_timeout_ms
         ) do
      {:ok, websocket_pid} -> {:ok, build_ws_stream(websocket_pid)}
      {:error, _reason} -> :fallback
    end
  end

  defp build_ws_stream(websocket_pid) do
    Stream.resource(
      fn -> websocket_pid end,
      fn websocket_pid = state ->
        receive do
          {:miosa_web_socket, ^websocket_pid, {:frame, {:text, data}}} ->
            case Jason.decode(data) do
              {:ok, event} -> {[event], state}
              {:error, _} -> {[%{"raw" => data}], state}
            end

          {:miosa_web_socket, ^websocket_pid, {:frame, {:binary, data}}} ->
            case Jason.decode(data) do
              {:ok, event} -> {[event], state}
              {:error, _} -> {[], state}
            end

          {:miosa_web_socket, ^websocket_pid, {:closed, _code, _reason}} ->
            {:halt, state}

          {:miosa_web_socket, ^websocket_pid, {:error, _reason}} ->
            {:halt, state}
        after
          30_000 ->
            _ = Miosa.WebSocket.send_frame(websocket_pid, :ping)
            {[], state}
        end
      end,
      &Miosa.WebSocket.close/1
    )
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp resource_id(%{id: id}), do: id
  defp resource_id(id) when is_binary(id), do: id

  defp encode_path_segment(value), do: URI.encode(value, &URI.char_unreserved?/1)
end
