# `Miosa.Sandbox.Share`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.1.0/lib/miosa/sandbox/share.ex#L1)

Public share URLs for a sandbox (read-only, no API key required at the proxy).

Wraps:
  * `POST   /sandboxes/:id/shares`            — create/3
  * `GET    /sandboxes/:id/shares`            — list/2
  * `DELETE /sandboxes/:id/shares/:share_id`  — revoke/3

The proxy accepts the query param `?ms=<token>` to authenticate share access.

# `create`

```elixir
@spec create(Miosa.Client.t(), String.t(), keyword()) :: Miosa.Client.result(map())
```

Create a share URL for a sandbox.

POST `/sandboxes/:sandbox_id/shares`

## Options
  * `:expires_in` — lifetime in seconds. Omit for no expiry.
  * `:scope`      — always `"read"` (only supported value). Defaults to `"read"`.

Returns `{:ok, %{"share_id" => _, "share_url" => _, "expires_at" => _, "scope" => _}}`.

# `list`

```elixir
@spec list(Miosa.Client.t(), String.t()) :: Miosa.Client.result(list())
```

List share URLs for a sandbox.

GET `/sandboxes/:sandbox_id/shares`

# `revoke`

```elixir
@spec revoke(Miosa.Client.t(), String.t(), String.t()) :: Miosa.Client.result(map())
```

Revoke a share URL.

DELETE `/sandboxes/:sandbox_id/shares/:share_id`

---

*Consult [api-reference.md](api-reference.md) for complete listing*
