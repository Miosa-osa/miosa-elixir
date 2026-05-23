# `Miosa.ApiKeys`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/api_keys.ex#L1)

API key management — programmatic CRUD for tenant API keys.

The plaintext token is returned **only at creation time**. Store it
immediately; the server only retains a hash.

Mutating calls (create) send an `Idempotency-Key` header automatically.

## Example

    client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

    {:ok, result} = Miosa.ApiKeys.create(client, %{
      name: "ci-deploy",
      scopes: ["computers:read", "computers:write"]
    })

    # Store result["token"] immediately — it will not be shown again.

    {:ok, keys} = Miosa.ApiKeys.list(client)
    :ok = Miosa.ApiKeys.delete(client, result["id"])

# `create`

```elixir
@spec create(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Create an API key.

Required: `:name`. Optional: `:scopes` (list of scope strings), `:expires_at`,
`:metadata`, `:idempotency_key`.

The response contains a one-time plaintext `:token` (or `"key"`). Store it
immediately; the server only keeps a hash.

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Revoke (delete) an API key by ID.

# `list`

```elixir
@spec list(Miosa.Client.t(), keyword() | map()) :: Miosa.Client.result(map())
```

List API keys for the authenticated tenant.

Note: The plaintext token is never returned by the list endpoint.
Accepts optional filters as a keyword list or map (e.g. `:limit`, `:cursor`).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
