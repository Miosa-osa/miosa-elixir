# `Miosa.Email.Templates`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/email.ex#L114)

Reusable email templates keyed by name (`/admin/email-templates`).

# `create`

```elixir
@spec create(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Create an email template (POST `/admin/email-templates`).

`key` is required — it uniquely identifies the template.

# `list`

```elixir
@spec list(Miosa.Client.t(), map()) :: Miosa.Client.result(list())
```

List email templates (GET `/admin/email-templates`).

# `reset`

```elixir
@spec reset(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Reset an email template to platform default (POST `/admin/email-templates/:key/reset`).

# `update`

```elixir
@spec update(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Update an email template (PUT `/admin/email-templates/:key`).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
