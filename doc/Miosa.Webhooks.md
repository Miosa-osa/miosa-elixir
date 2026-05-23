# `Miosa.Webhooks`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/webhooks.ex#L1)

Tenant-level outgoing webhooks — CRUD, test delivery, and delivery history.

Mutating calls (create, update, test) send an `Idempotency-Key` header
automatically.

## Example

    client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

    {:ok, wh} = Miosa.Webhooks.create(client, %{
      url: "https://api.example.com/hooks/miosa",
      events: ["computer.started", "computer.stopped"],
      secret: "whsec_..."
    })

    {:ok, _} = Miosa.Webhooks.test(client, wh["id"])
    {:ok, deliveries} = Miosa.Webhooks.deliveries(client, wh["id"])

# `create`

```elixir
@spec create(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Create a webhook.

Required: `:url`, `:events` (list of event type strings).
Optional: `:secret`, `:enabled`, `:metadata`, `:idempotency_key`.

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Delete a webhook by ID.

# `deliveries`

```elixir
@spec deliveries(Miosa.Client.t(), String.t(), keyword() | map()) ::
  Miosa.Client.result(map())
```

List recent delivery attempts for a webhook.

Accepts optional filters as a keyword list or map (e.g. `:limit`, `:cursor`).

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Fetch a webhook by ID.

# `list`

```elixir
@spec list(Miosa.Client.t(), keyword() | map()) :: Miosa.Client.result(map())
```

List webhooks for the authenticated tenant.

Accepts optional filters as a keyword list or map (e.g. `:limit`, `:cursor`).

# `test`

```elixir
@spec test(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Send a test event to verify the webhook endpoint is reachable.

# `update`

```elixir
@spec update(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Update a webhook.

Pass any fields to update; nil values are dropped.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
