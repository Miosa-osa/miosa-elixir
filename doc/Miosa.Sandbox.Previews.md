# `Miosa.Sandbox.Previews`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/sandbox/previews.ex#L1)

Preview URL management for a sandbox.

Wraps `/sandboxes/:id/previews/*` — list, create, get, delete,
share (mint token), and revoke share tokens.

# `create`

```elixir
@spec create(Miosa.Client.t(), String.t(), pos_integer(), map()) ::
  Miosa.Client.result(map())
```

Create a new preview for a port (POST `/sandboxes/:sandbox_id/previews`).

`port` is required. Additional opts are merged into the body.

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t(), String.t()) ::
  :ok | {:error, Miosa.Error.t()}
```

Delete a preview (DELETE `/sandboxes/:sandbox_id/previews/:preview_id`).

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t(), String.t()) :: Miosa.Client.result(map())
```

Get a preview by ID (GET `/sandboxes/:sandbox_id/previews/:preview_id`).

# `list`

```elixir
@spec list(Miosa.Client.t(), String.t()) :: Miosa.Client.result(list())
```

List preview records for a sandbox (GET `/sandboxes/:sandbox_id/previews`).

# `revoke_share`

```elixir
@spec revoke_share(Miosa.Client.t(), String.t(), String.t()) ::
  :ok | {:error, Miosa.Error.t()}
```

Invalidate every share token for a preview
(DELETE `/sandboxes/:sandbox_id/previews/:preview_id/share`).

# `share`

```elixir
@spec share(Miosa.Client.t(), String.t(), String.t(), pos_integer()) ::
  Miosa.Client.result(map())
```

Mint a share token for a preview
(POST `/sandboxes/:sandbox_id/previews/:preview_id/share`).

`expires_in_sec` defaults to `3600` (one hour).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
