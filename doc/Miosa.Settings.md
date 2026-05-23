# `Miosa.Settings`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/settings.ex#L1)

Tenant settings — workspace config, branding, and BYOK provider keys.

## Example

    client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

    {:ok, settings} = Miosa.Settings.get(client)
    {:ok, _updated} = Miosa.Settings.update(client, %{default_region: "us-east"})

# `available_models`

```elixir
@spec available_models(Miosa.Client.t()) :: Miosa.Client.result(map())
```

List models available to this tenant.

# `compute_pricing`

```elixir
@spec compute_pricing(Miosa.Client.t()) :: Miosa.Client.result(map())
```

Get tenant-scoped compute pricing.

# `delete_provider_key`

```elixir
@spec delete_provider_key(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Delete a BYOK provider key by provider name.

# `get`

```elixir
@spec get(Miosa.Client.t()) :: Miosa.Client.result(map())
```

Get the current tenant settings.

# `get_branding`

```elixir
@spec get_branding(Miosa.Client.t()) :: Miosa.Client.result(map())
```

Get tenant branding (logo, colors, custom wordmark).

# `gpu_pricing`

```elixir
@spec gpu_pricing(Miosa.Client.t()) :: Miosa.Client.result(map())
```

Get tenant-scoped GPU pricing.

# `list_provider_keys`

```elixir
@spec list_provider_keys(Miosa.Client.t()) :: Miosa.Client.result(map())
```

List tenant-level BYOK provider keys (Anthropic, OpenAI, etc.).

# `regions`

```elixir
@spec regions(Miosa.Client.t()) :: Miosa.Client.result(map())
```

List regions enabled for this tenant.

# `update`

```elixir
@spec update(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Update tenant settings.

Pass any settable fields as a map.

# `update_branding`

```elixir
@spec update_branding(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Update tenant branding.

# `upsert_provider_key`

```elixir
@spec upsert_provider_key(Miosa.Client.t(), String.t(), map()) ::
  Miosa.Client.result(map())
```

Create or update a BYOK provider key.

Required: `provider` (e.g. `"anthropic"`) and `attrs` map containing at
minimum `%{key: "sk-..."}`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
