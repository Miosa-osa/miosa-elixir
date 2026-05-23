defmodule Miosa.Audit do
  @moduledoc """
  Tenant-wide egress audit log.

  Backed by `GET /api/v1/egress/audit` and `GET /api/v1/egress/audit/:id`.

  `tail/3` returns a lazy `Stream` that long-polls the REST endpoint and
  yields new audit events as they arrive. For a WebSocket-backed sub-second
  tail, use the sandbox-bound `Miosa.Sandboxes.Audit.tail/2` which upgrades
  to the per-resource stream endpoint.

  ## Client-level usage

      client = Miosa.client("msk_u_...")

      {:ok, events} = Miosa.Audit.list(client, %{resource_id: "sb_123"})
      {:ok, event}  = Miosa.Audit.get(client, event_id)

      # Long-poll tail — returns a lazy Stream
      stream = Miosa.Audit.tail(client, nil, poll_interval_ms: 3_000)
      stream |> Stream.take(10) |> Enum.to_list()

  ## Sandbox-bound usage

  See `Miosa.Sandboxes.Audit` for the resource-scoped variant that upgrades
  to a WebSocket stream.
  """

  alias Miosa.Client

  @audit_path "/egress/audit"
  @default_poll_interval_ms 2_000

  # ---------------------------------------------------------------------------
  # Query
  # ---------------------------------------------------------------------------

  @doc """
  List audit events.

  Accepts an optional `filters` map with any combination of:
  `resource_id`, `resource_type`, `host`, `action`, `since`, `until`,
  `limit`, `cursor`, `external_user_id`, `external_workspace_id`.
  """
  @spec list(Client.t(), map()) :: Client.result([map()])
  def list(%Client{} = client, filters \\ %{}) do
    params = filters |> strip_nil() |> map_to_keyword()

    case Client.get(client, @audit_path, params: params) do
      {:ok, data} -> {:ok, unwrap_list(data)}
      err -> err
    end
  end

  @doc """
  Fetch a single audit event by ID.
  """
  @spec get(Client.t(), String.t()) :: Client.result(map())
  def get(%Client{} = client, event_id) when is_binary(event_id) do
    case Client.get(client, "#{@audit_path}/#{event_id}") do
      {:ok, data} -> {:ok, unwrap(data)}
      err -> err
    end
  end

  # ---------------------------------------------------------------------------
  # Tail (long-poll stream)
  # ---------------------------------------------------------------------------

  @doc """
  Return a lazy `Stream` that long-polls the audit endpoint and emits new
  events as they appear.

  The stream is **infinite** — call `Stream.take/2` or `Enum.take/2` to
  bound it, or `Stream.run/1` to consume it until the caller's process exits.

  This is a REST-based long-poll. For a live WebSocket tail scoped to a
  specific sandbox, use `Miosa.Sandboxes.Audit.tail/2` instead.

  ## Arguments

    * `client` — a `Miosa.Client` struct.
    * `resource_id` — optional resource ID to scope the tail.

  ## Options (keyword)

    * `:resource_type` — `"sandbox"` or `"computer"` (optional).
    * `:host` — filter by egress host.
    * `:action` — filter by action type.
    * `:since` — ISO-8601 timestamp or relative string to start from.
    * `:poll_interval_ms` — milliseconds between polls. Defaults to `2_000`.
  """
  @spec tail(Client.t(), String.t() | nil, keyword()) :: Enumerable.t()
  def tail(%Client{} = client, resource_id \\ nil, opts \\ []) do
    poll_interval_ms = Keyword.get(opts, :poll_interval_ms, @default_poll_interval_ms)

    base_filters =
      opts
      |> Keyword.drop([:poll_interval_ms])
      |> Enum.into(%{})
      |> then(fn m ->
        m
        |> maybe_put(:resource_id, resource_id)
        |> maybe_put(:resource_type, Keyword.get(opts, :resource_type))
      end)
      |> strip_nil()

    build_poll_stream(client, base_filters, poll_interval_ms)
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp build_poll_stream(client, base_filters, poll_interval_ms) do
    # Initial state: {since :: String.t() | nil, seen_ids :: MapSet.t()}
    Stream.resource(
      fn -> {Map.get(base_filters, :since), MapSet.new()} end,
      fn {since, seen_ids} ->
        params =
          base_filters
          |> maybe_put(:since, since)
          |> strip_nil()
          |> map_to_keyword()

        events =
          case Client.get(client, @audit_path, params: params) do
            {:ok, data} -> unwrap_list(data)
            {:error, _} -> []
          end

        {new_events, new_seen, new_since} =
          Enum.reduce(events, {[], seen_ids, since}, fn event, {acc, ids, ts} ->
            eid = Map.get(event, "id")

            if eid && MapSet.member?(ids, to_string(eid)) do
              {acc, ids, ts}
            else
              new_ids = if eid, do: MapSet.put(ids, to_string(eid)), else: ids

              new_ts =
                case Map.get(event, "inserted_at") || Map.get(event, "timestamp") do
                  s when is_binary(s) -> s
                  _ -> ts
                end

              {[event | acc], new_ids, new_ts}
            end
          end)

        Process.sleep(poll_interval_ms)
        {Enum.reverse(new_events), {new_since, new_seen}}
      end,
      fn _state -> :ok end
    )
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  @spec strip_nil(map()) :: map()
  defp strip_nil(map) when is_map(map) do
    Map.reject(map, fn {_k, v} -> is_nil(v) end)
  end

  @spec map_to_keyword(map()) :: keyword()
  defp map_to_keyword(map) when is_map(map) do
    Enum.map(map, fn {k, v} -> {to_key(k), v} end)
  end

  defp to_key(k) when is_atom(k), do: k
  defp to_key(k) when is_binary(k), do: String.to_existing_atom(k)

  @spec unwrap(any()) :: any()
  defp unwrap(%{"data" => inner} = map) when map_size(map) <= 2, do: inner
  defp unwrap(%{"event" => inner} = map) when map_size(map) <= 2, do: inner
  defp unwrap(other), do: other

  @spec unwrap_list(any()) :: [map()]
  defp unwrap_list(list) when is_list(list), do: list

  defp unwrap_list(map) when is_map(map) do
    keys = ["data", "events", "audit", "items"]

    Enum.find_value(keys, [], fn key ->
      case Map.get(map, key) do
        list when is_list(list) -> list
        _ -> nil
      end
    end)
  end

  defp unwrap_list(_), do: []
end
