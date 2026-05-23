# `Miosa.Functions`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/functions.ex#L1)

Edge functions — serverless, request-driven code that runs close to the user.

Functions support full CRUD and can be invoked synchronously.
Mutating calls send an `Idempotency-Key` header automatically.

## Example

    client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

    {:ok, fn_} = Miosa.Functions.create(client, %{
      name: "resize-image",
      runtime: "node18",
      source: "export default (req) => new Response('ok')"
    })

    {:ok, result} = Miosa.Functions.invoke(client, fn_["id"], %{
      payload: %{url: "https://example.com/logo.png"}
    })

# `create`

```elixir
@spec create(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Create a function.

Required: `:name`. Optional: `:runtime`, `:source`, `:env`, `:metadata`,
`:idempotency_key`.

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Delete a function by ID.

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Fetch a function by ID.

# `invoke`

```elixir
@spec invoke(Miosa.Client.t(), String.t(), keyword() | map()) ::
  Miosa.Client.result(map())
```

Invoke a function synchronously.

Optional `opts`:
  * `:payload` — Map to send as the request body.
  * `:idempotency_key` — Idempotency key for the invocation.

# `list`

```elixir
@spec list(Miosa.Client.t(), keyword() | map()) :: Miosa.Client.result(map())
```

List functions for the authenticated tenant.

Accepts optional filters as a keyword list or map (e.g. `:limit`, `:cursor`).

# `update`

```elixir
@spec update(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Update a function.

Pass any fields to update; nil values are dropped.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
