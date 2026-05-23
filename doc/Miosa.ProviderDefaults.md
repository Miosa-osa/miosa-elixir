# `Miosa.ProviderDefaults`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/provider_defaults.ex#L1)

Admin LLM provider routing config.

Routes live under `/api/v1/admin/provider-defaults` and per-tenant
overrides under `/api/v1/admin/tenants/:id/provider-config`. Requires an
admin credential (`msk_a_*` / `msk_p_*` or admin JWT).

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Return the defaults entry for a single provider name, or `{:ok, %{}}` if not found.

# `get_tenant`

```elixir
@spec get_tenant(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Get per-tenant provider config override (GET `/admin/tenants/:tenant_id/provider-config`).

# `list`

```elixir
@spec list(Miosa.Client.t()) :: Miosa.Client.result(map())
```

Get the current fleet-wide provider defaults (GET `/admin/provider-defaults`).

# `reset_tenant`

```elixir
@spec reset_tenant(Miosa.Client.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
```

Delete per-tenant provider config override (DELETE `/admin/tenants/:tenant_id/provider-config`).

# `set_tenant`

```elixir
@spec set_tenant(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Set per-tenant provider config override (PUT `/admin/tenants/:tenant_id/provider-config`).

# `update`

```elixir
@spec update(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Replace the fleet-wide defaults (PUT `/admin/provider-defaults`).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
