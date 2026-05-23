# `Miosa.Email.Inbox`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/email.ex#L190)

Inbound and outbound direct messages (`/admin/email-inbox`).

# `archive`

```elixir
@spec archive(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Archive a message (POST `/admin/email-inbox/:message_id/archive`).

# `list`

```elixir
@spec list(Miosa.Client.t(), map()) :: Miosa.Client.result(list())
```

List inbox messages (GET `/admin/email-inbox`).

# `mark_read`

```elixir
@spec mark_read(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Mark a message as read (POST `/admin/email-inbox/:message_id/read`).

# `send`

```elixir
@spec send(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Send a direct message (POST `/admin/email-inbox/send`).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
