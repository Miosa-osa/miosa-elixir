# `Miosa.Channels`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/channels.ex#L1)

Notification channels — Slack, Discord, email, and per-channel enable/disable.

## Example

    client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

    {:ok, channels} = Miosa.Channels.list(client)
    {:ok, channel} = Miosa.Channels.create(client, %{type: "slack", webhook_url: "https://..."})
    {:ok, _} = Miosa.Channels.enable(client, channel["id"])

# `create`

```elixir
@spec create(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Create a new notification channel.

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Delete a channel by ID.

# `disable`

```elixir
@spec disable(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Disable a channel by ID.

# `enable`

```elixir
@spec enable(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Enable a channel by ID.

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Get a single channel by ID.

# `list`

```elixir
@spec list(Miosa.Client.t(), keyword() | map()) :: Miosa.Client.result(map())
```

List all channels for the tenant.

Accepts optional filters as a keyword list or map.

# `list_notifications`

```elixir
@spec list_notifications(Miosa.Client.t()) :: Miosa.Client.result(map())
```

Get notification preferences across all channels.

# `update`

```elixir
@spec update(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Update a channel by ID.

# `update_notifications`

```elixir
@spec update_notifications(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Update notification preferences.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
