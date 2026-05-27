# `Miosa.WorkspaceMembers`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.1.0/lib/miosa/workspace_members.ex#L1)

Per-workspace user roster — list, add, update role, remove.

A workspace member must already be a tenant (org) member. The last
owner of a workspace cannot be removed without first promoting another
member to owner.

## Example

    client = Miosa.client("msk_u_...")

    {:ok, members} = Miosa.WorkspaceMembers.list(client, workspace_id)
    {:ok, record}  = Miosa.WorkspaceMembers.add(client, workspace_id, user_id, "member")
    {:ok, record}  = Miosa.WorkspaceMembers.update_role(client, workspace_id, user_id, "admin")
    {:ok, _}       = Miosa.WorkspaceMembers.remove(client, workspace_id, user_id)

## Endpoints

  * `GET    /workspaces/:id/members`
  * `POST   /workspaces/:id/members`
  * `PATCH  /workspaces/:id/members/:user_id`
  * `DELETE /workspaces/:id/members/:user_id`

# `workspace_role`

```elixir
@type workspace_role() :: :owner | :admin | :member | :viewer
```

# `add`

```elixir
@spec add(Miosa.Client.t(), String.t(), String.t(), String.t()) ::
  {:ok, map()} | {:error, term()}
```

Adds an existing tenant user to the workspace.

The `user_id` must already hold a `tenant_members` row for the parent org.
To invite someone who is not yet an org member, use
`Miosa.WorkspaceInvites.create/5`.

Returns `{:error, :not_tenant_member}` (via server 422) if the user is not
an org member.

## Example

    {:ok, record} = Miosa.WorkspaceMembers.add(client, ws_id, user_id, "member")

# `list`

```elixir
@spec list(Miosa.Client.t(), String.t()) :: {:ok, [map()]} | {:error, term()}
```

Returns all members of the given workspace.

Each element includes denormalised user fields (email, name, avatar_url)
for display.

## Example

    {:ok, members} = Miosa.WorkspaceMembers.list(client, "ws-uuid")
    Enum.each(members, &IO.inspect/1)

# `remove`

```elixir
@spec remove(Miosa.Client.t(), String.t(), String.t()) ::
  {:ok, map()} | {:error, term()}
```

Removes a user from the workspace.

The last owner cannot be removed. Returns `{:error, :last_owner}` (via
server 409) when the target is the sole owner.

## Example

    :ok = Miosa.WorkspaceMembers.remove(client, ws_id, user_id)

# `update_role`

```elixir
@spec update_role(Miosa.Client.t(), String.t(), String.t(), String.t()) ::
  {:ok, map()} | {:error, term()}
```

Changes a workspace member's role.

## Example

    {:ok, record} = Miosa.WorkspaceMembers.update_role(client, ws_id, user_id, "admin")

---

*Consult [api-reference.md](api-reference.md) for complete listing*
