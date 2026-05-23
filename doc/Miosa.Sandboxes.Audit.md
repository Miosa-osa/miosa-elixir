# `Miosa.Sandboxes.Audit`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/sandboxes/audit.ex#L1)

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

# `get`

```elixir
@spec get(map() | String.t(), Miosa.Client.t(), String.t()) ::
  Miosa.Client.result(map())
```

Fetch a single audit event by ID.

# `list`

```elixir
@spec list(map() | String.t(), Miosa.Client.t(), map()) ::
  Miosa.Client.result([map()])
```

List audit events for this sandbox.

Accepts the same optional `filters` map as `Miosa.Audit.list/2`.

# `tail`

```elixir
@spec tail(map() | String.t(), Miosa.Client.t(), keyword()) ::
  {:ok, Enumerable.t()} | {:error, Miosa.Error.t()}
```

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

---

*Consult [api-reference.md](api-reference.md) for complete listing*
