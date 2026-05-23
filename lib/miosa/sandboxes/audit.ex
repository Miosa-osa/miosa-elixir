defmodule Miosa.Sandboxes.Audit do
  @moduledoc """
  Sandbox-bound view of `Miosa.Audit`.

  `list/3` pre-scopes `resource_id` and `resource_type="sandbox"`.

  `tail/2` opens a live WebSocket connection to the per-sandbox stream
  endpoint (`/api/v1/egress/audit/resource/:resource_id`) using `:gun`
  (which is already a project dependency). The subprotocol is
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

  Internally opens a `:gun` WebSocket to
  `/api/v1/egress/audit/resource/:resource_id` using subprotocol
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
  # Private — WebSocket stream via :gun
  # ---------------------------------------------------------------------------

  defp try_ws_stream(client, resource_id, _poll_interval_ms) do
    uri = URI.parse(client.base_url)
    host = String.to_charlist(uri.host || "api.miosa.ai")
    port = uri.port || if(uri.scheme == "https", do: 443, else: 80)
    secure? = uri.scheme == "https"

    transport = if secure?, do: :tls, else: :tcp

    gun_opts = %{
      protocols: [:http],
      transport: transport,
      connect_timeout: @ws_connect_timeout_ms,
      tls_opts: [verify: :verify_peer, cacerts: :public_key.cacerts_get()]
    }

    path =
      (uri.path || "/api/v1") <>
        "/egress/audit/resource/#{resource_id}" <>
        "?token=#{URI.encode(client.api_key)}"

    case :gun.open(host, port, gun_opts) do
      {:ok, conn_pid} ->
        case :gun.await_up(conn_pid, @ws_connect_timeout_ms) do
          {:ok, _protocol} ->
            stream_ref =
              :gun.ws_upgrade(conn_pid, path, [
                {<<"sec-websocket-protocol">>, @ws_subprotocol}
              ])

            case await_ws_upgrade(conn_pid, stream_ref) do
              :ok ->
                {:ok, build_ws_stream(conn_pid, stream_ref)}

              :error ->
                :gun.close(conn_pid)
                :fallback
            end

          {:error, _} ->
            :gun.close(conn_pid)
            :fallback
        end

      {:error, _} ->
        :fallback
    end
  end

  defp await_ws_upgrade(conn_pid, stream_ref) do
    receive do
      {:gun_upgrade, ^conn_pid, ^stream_ref, [<<"websocket">>], _headers} ->
        :ok

      {:gun_response, ^conn_pid, ^stream_ref, _, status, _headers} when status >= 400 ->
        :error

      {:gun_error, ^conn_pid, ^stream_ref, _reason} ->
        :error
    after
      @ws_connect_timeout_ms -> :error
    end
  end

  defp build_ws_stream(conn_pid, stream_ref) do
    Stream.resource(
      fn -> {conn_pid, stream_ref} end,
      fn {cpid, sref} = state ->
        receive do
          {:gun_ws, ^cpid, ^sref, {:text, data}} ->
            case Jason.decode(data) do
              {:ok, event} -> {[event], state}
              {:error, _} -> {[%{"raw" => data}], state}
            end

          {:gun_ws, ^cpid, ^sref, {:binary, data}} ->
            case Jason.decode(data) do
              {:ok, event} -> {[event], state}
              {:error, _} -> {[], state}
            end

          {:gun_ws, ^cpid, ^sref, :close} ->
            {:halt, state}

          {:gun_ws, ^cpid, ^sref, {:close, _code, _reason}} ->
            {:halt, state}

          {:gun_down, ^cpid, _protocol, _reason, _killed} ->
            {:halt, state}
        after
          30_000 ->
            # Send a ping to keep the connection alive and keep waiting.
            :gun.ws_send(cpid, sref, :ping)
            {[], state}
        end
      end,
      fn {cpid, _sref} ->
        :gun.close(cpid)
      end
    )
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp resource_id(%{id: id}), do: id
  defp resource_id(id) when is_binary(id), do: id
end
