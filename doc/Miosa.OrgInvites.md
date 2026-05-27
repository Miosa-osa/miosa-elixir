# `Miosa.OrgInvites`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.1.0/lib/miosa/org_invites.ex#L1)

Email invite flow for org (tenant) membership.

Invites are scoped to a tenant and carry a role. The accept endpoint
requires a valid JWT / API key so the platform knows which user is
claiming the invite. Email-match is enforced case-insensitively.

## Example

    client = Miosa.client("msk_u_...")

    {:ok, created} = Miosa.OrgInvites.create(client, tenant_id, "bob@example.com", "member")
    IO.inspect(created["invite_url"])

    {:ok, invites} = Miosa.OrgInvites.list(client, tenant_id)
    {:ok, _}       = Miosa.OrgInvites.revoke(client, tenant_id, List.first(invites)["id"])

    {:ok, preview} = Miosa.OrgInvites.preview(client, token)
    unless preview["expired"] do
      {:ok, _} = Miosa.OrgInvites.accept(client, token)
    end

## Endpoints

  * `POST   /tenants/:id/invites`              (admin/owner required)
  * `GET    /tenants/:id/invites`              (admin/owner required)
  * `DELETE /tenants/:id/invites/:invite_id`   (admin/owner required)
  * `GET    /invites/:token`                   (public, no auth)
  * `POST   /invites/:token/accept`            (auth required)

# `accept`

```elixir
@spec accept(Miosa.Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
```

Accepts an org invite on behalf of the authenticated user.

The caller's API key email must match the invite email (case-insensitive).
On success inserts a `tenant_members` row.

Error atoms (from server response):
  - `:invalid_token` (400) — token not found or expired.
  - `:email_mismatch` (422) — session email differs from invite email.

## Example

    {:ok, result} = Miosa.OrgInvites.accept(client, token)
    IO.puts("joined org: #{result["tenant_id"]}")

# `create`

```elixir
@spec create(Miosa.Client.t(), String.t(), String.t(), String.t()) ::
  {:ok, map()} | {:error, term()}
```

Creates an org invite and dispatches the invite email.

The response includes an `invite_url` that is host-aware: on white-label
tenants it uses the tenant's custom domain.

Requires `admin` or `owner` role in the tenant.

## Example

    {:ok, created} = Miosa.OrgInvites.create(client, tenant_id, "bob@example.com", "member")
    IO.puts("invite URL: #{created["invite_url"]}")

# `list`

```elixir
@spec list(Miosa.Client.t(), String.t()) :: {:ok, [map()]} | {:error, term()}
```

Lists all pending org invites.

Requires `admin` or `owner` role.

## Example

    {:ok, invites} = Miosa.OrgInvites.list(client, tenant_id)

# `preview`

```elixir
@spec preview(Miosa.Client.t(), String.t()) ::
  {:ok, map()} | {:error, :not_found | term()}
```

Returns a public preview of the org invite by token (no auth required).

Use this to render the pre-auth invite landing page. Returns
`{:error, :not_found}` when the token is unknown or has been revoked.

## Example

    {:ok, preview} = Miosa.OrgInvites.preview(client, token)
    IO.inspect(preview["tenant_name"])

# `revoke`

```elixir
@spec revoke(Miosa.Client.t(), String.t(), String.t()) ::
  {:ok, map()} | {:error, term()}
```

Revokes a pending org invite.

Returns `{:error, :already_accepted}` (via server 409) when the invite was
already legitimately accepted.

Requires `admin` or `owner` role.

## Example

    {:ok, _} = Miosa.OrgInvites.revoke(client, tenant_id, invite_id)

---

*Consult [api-reference.md](api-reference.md) for complete listing*
