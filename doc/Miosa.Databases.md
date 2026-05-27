# `Miosa.Databases`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/databases.ex#L1)

Managed Postgres databases — CRUD, lifecycle, credentials, logs.

All mutating calls send an `Idempotency-Key` header automatically.
Supply `:idempotency_key` in `attrs` to use your own.

## Example

    client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

    {:ok, db} = Miosa.Databases.create(client, %{name: "my-db", plan: "starter"})
    {:ok, creds} = Miosa.Databases.credentials(client, db["id"])
    IO.puts(creds["url"])

# `create`

```elixir
@spec create(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Create a database.

Required: `:name`. Optional: `:plan`, `:region`, and any other attrs accepted
by the API. Pass `:idempotency_key` to supply your own key.

# `credentials`

```elixir
@spec credentials(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Get connection credentials (URL, host, port, user, password) for a database.

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Delete a database by ID.

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Fetch a database by ID.

# `list`

```elixir
@spec list(Miosa.Client.t(), keyword() | map()) :: Miosa.Client.result(map())
```

List databases for the authenticated tenant.

Accepts optional filters as a keyword list or map (e.g. `:limit`, `:cursor`).

# `logs`

```elixir
@spec logs(Miosa.Client.t(), String.t(), keyword() | map()) ::
  Miosa.Client.result(map())
```

Get recent logs for a database.

Options:
  * `:lines` — Number of log lines to return.
  * `:since` — ISO 8601 timestamp to fetch logs since.

# `restart`

```elixir
@spec restart(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Restart a database.

# `start`

```elixir
@spec start(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Start a stopped database.

# `stop`

```elixir
@spec stop(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Stop a running database.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
