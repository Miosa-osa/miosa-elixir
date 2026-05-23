# `Miosa.Audit`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/audit.ex#L1)

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

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Fetch a single audit event by ID.

# `list`

```elixir
@spec list(Miosa.Client.t(), map()) :: Miosa.Client.result([map()])
```

List audit events.

Accepts an optional `filters` map with any combination of:
`resource_id`, `resource_type`, `host`, `action`, `since`, `until`,
`limit`, `cursor`, `external_user_id`, `external_workspace_id`.

# `tail`

```elixir
@spec tail(Miosa.Client.t(), String.t() | nil, keyword()) :: Enumerable.t()
```

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

---

*Consult [api-reference.md](api-reference.md) for complete listing*
