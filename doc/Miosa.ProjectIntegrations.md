# `Miosa.ProjectIntegrations`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/project_integrations.ex#L1)

Per-project integrations — Stripe, Resend, Twilio, and similar third-party
provider keys injected as env vars into sandbox/deployment VMs at boot.

Credentials are encrypted at rest.

## Example

    client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

    {:ok, catalog} = Miosa.ProjectIntegrations.catalog(client)
    {:ok, integration} = Miosa.ProjectIntegrations.create(client, %{
      provider: "stripe",
      secret_key: "sk_live_..."
    })

# `catalog`

```elixir
@spec catalog(Miosa.Client.t()) :: Miosa.Client.result(map())
```

List supported providers and their configuration schemas.

# `create`

```elixir
@spec create(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Create a project integration.

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Delete a project integration by ID.

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Get a project integration by ID.

# `list`

```elixir
@spec list(Miosa.Client.t(), keyword() | map()) :: Miosa.Client.result(map())
```

List project integrations.

Accepts optional filters as a keyword list or map.

# `update`

```elixir
@spec update(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Update a project integration by ID.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
