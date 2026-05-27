# `Miosa.FlatCustomDomains`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/flat_custom_domains.ex#L1)

Tenant-scoped custom domain management across all computers and deployments.

This is the flat listing at `/custom-domains`. Per-deployment domain
management lives in `Miosa.Deployments` (e.g. `add_domain/3`, `list_domains/2`).

## Example

    client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

    {:ok, domain} = Miosa.FlatCustomDomains.create(client, %{
      domain: "app.example.com",
      target_id: "depl_abc123",
      target_type: "deployment"
    })

    {:ok, _} = Miosa.FlatCustomDomains.list(client)

# `create`

```elixir
@spec create(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Attach a custom domain.

Required: `:domain`. Optional: `:target_id`, `:target_type`, `:redirect_policy`,
attribution fields, `:idempotency_key`.

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Delete a custom domain by ID.

# `list`

```elixir
@spec list(Miosa.Client.t(), keyword() | map()) :: Miosa.Client.result(map())
```

List all custom domains for the authenticated tenant.

Accepts optional filters as a keyword list or map (e.g. `:limit`, `:cursor`,
`:target_type`).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
