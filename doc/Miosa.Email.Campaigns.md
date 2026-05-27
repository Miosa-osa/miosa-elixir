# `Miosa.Email.Campaigns`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/email.ex#L16)

Admin email campaign lifecycle (GET/POST/etc. `/admin/email-campaigns`).

# `cancel`

```elixir
@spec cancel(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Cancel a campaign (POST `/admin/email-campaigns/:campaign_id/cancel`).

# `create`

```elixir
@spec create(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Create an email campaign (POST `/admin/email-campaigns`).

# `deliveries`

```elixir
@spec deliveries(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(list())
```

List per-recipient delivery records (GET `/admin/email-campaigns/:campaign_id/deliveries`).

# `list`

```elixir
@spec list(Miosa.Client.t(), map()) :: Miosa.Client.result(list())
```

List email campaigns (GET `/admin/email-campaigns`).

# `recipient_count`

```elixir
@spec recipient_count(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Get estimated recipient count (GET `/admin/email-campaigns/recipient-count`).

# `send`

```elixir
@spec send(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Trigger send for a campaign (POST `/admin/email-campaigns/:campaign_id/send`).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
