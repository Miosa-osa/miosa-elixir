# `Miosa.Tokens`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.1.0/lib/miosa/tokens.ex#L1)

Layer 2 scoped delegation tokens.

White-label customers (e.g. ClinicIQ) authenticate with a master `msk_*` key
and mint short-lived JWTs bound to a specific end-user and workspace. The
resulting token carries only the requested scopes — no privilege escalation
beyond the caller's own scopes is possible.

## Example

    client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

    {:ok, result} = Miosa.Tokens.create_scoped(client, %{
      user_id: "end-user-123",
      workspace_id: "ws_abc...",
      expires_in_seconds: 3600,
      scopes: ["sandboxes:create", "sandboxes:exec"]
    })

    # result["token"]      — JWT to embed in the client-side app
    # result["expires_at"] — ISO 8601 expiry
    # result["scopes"]     — granted scopes

# `create_scoped`

```elixir
@spec create_scoped(Miosa.Client.t(), map() | keyword()) :: Miosa.Client.result(map())
```

Mint a short-lived scoped delegation token.

The caller must authenticate with a Layer 1 tenant master key. The resulting
JWT is bound to `user_id` + `workspace_id` and expires after
`expires_in_seconds` (default: 3600, max: 86400).

Required fields:
- `:user_id`       — opaque end-user identifier (string)
- `:workspace_id`  — UUID, must belong to caller's tenant

Optional fields:
- `:expires_in_seconds` — positive integer ≤ 86400 (default 3600)
- `:scopes`             — subset of caller's scopes (default: inherit all)

---

*Consult [api-reference.md](api-reference.md) for complete listing*
