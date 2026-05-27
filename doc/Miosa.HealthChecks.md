# `Miosa.HealthChecks`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/health_checks.ex#L1)

Health checks — uptime monitoring for URLs and TCP endpoints.

Mutating calls (create, update) send an `Idempotency-Key` header automatically.

## Example

    client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

    {:ok, check} = Miosa.HealthChecks.create(client, %{
      name: "API health",
      url: "https://api.example.com/health",
      interval_seconds: 60
    })

    {:ok, _} = Miosa.HealthChecks.get(client, check["id"])

# `create`

```elixir
@spec create(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Create a health check.

Required: `:name`, `:url`. Optional: `:interval_seconds`, `:timeout_seconds`,
`:expected_status`, `:method`, `:headers`, `:idempotency_key`.

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Delete a health check by ID.

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Fetch a health check by ID.

# `list`

```elixir
@spec list(Miosa.Client.t(), keyword() | map()) :: Miosa.Client.result(map())
```

List health checks for the authenticated tenant.

Accepts optional filters as a keyword list or map (e.g. `:limit`, `:cursor`).

# `update`

```elixir
@spec update(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Update a health check.

Pass any fields to update; nil values are dropped.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
