# `Miosa.Integrations`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/integrations.ex#L1)

OAuth account-level integrations — GitHub, Slack, Linear, Discord.

## Example

    client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

    {:ok, integrations} = Miosa.Integrations.list(client)
    {:ok, %{"url" => url}} = Miosa.Integrations.start(client, "github")

# `catalog`

```elixir
@spec catalog(Miosa.Client.t()) :: Miosa.Client.result(map())
```

List available providers in the integration catalog.

# `disconnect`

```elixir
@spec disconnect(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Disconnect (revoke) an integration by provider name.

# `discord_send_test`

```elixir
@spec discord_send_test(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Send a test message to the connected Discord channel.

# `github_repos`

```elixir
@spec github_repos(Miosa.Client.t()) :: Miosa.Client.result(map())
```

List GitHub repositories accessible to this integration.

# `github_ssh_keys`

```elixir
@spec github_ssh_keys(Miosa.Client.t()) :: Miosa.Client.result(map())
```

List configured GitHub deploy (SSH) keys.

# `linear_create_issue`

```elixir
@spec linear_create_issue(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Create a Linear issue via the connected workspace.

# `linear_start`

```elixir
@spec linear_start(Miosa.Client.t()) :: Miosa.Client.result(map())
```

Begin the Linear OAuth flow.

# `list`

```elixir
@spec list(Miosa.Client.t()) :: Miosa.Client.result(map())
```

List active OAuth integrations for the tenant.

# `refresh`

```elixir
@spec refresh(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Force-refresh the access token for a connected provider.

# `slack_send_test`

```elixir
@spec slack_send_test(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Send a test message to the connected Slack channel.

# `start`

```elixir
@spec start(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Begin the OAuth flow for a provider — returns an authorize URL.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
