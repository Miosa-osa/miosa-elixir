# `Miosa.BuilderSessions`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/builder_sessions.ex#L1)

Builder UI session metadata — durable, cross-device Builder state.

Routes live under `/api/v1/builder/sessions/` and accept `msk_*` API
keys or JWT. Builder sessions are `optimal_sessions` with
`resource_type = "sandbox"` and `vm_context.template_type = "miosa-sandbox"`.

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
```

Delete a builder session (DELETE `/builder/sessions/:session_id`).

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map() | nil)
```

Get a single builder session by ID.

Falls back to filtering `list/2` since the platform router only exposes
index + title-update + delete.

# `list`

```elixir
@spec list(Miosa.Client.t(), Keyword.t()) :: Miosa.Client.result(list())
```

List builder sessions (GET `/builder/sessions`).

## Options

  * `:limit` — Maximum sessions to return. Defaults to `50`.
  * Any extra key is forwarded as a query param.

# `update_title`

```elixir
@spec update_title(Miosa.Client.t(), String.t(), String.t()) ::
  Miosa.Client.result(map())
```

Update the title of a builder session
(PATCH `/builder/sessions/:session_id/title`).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
