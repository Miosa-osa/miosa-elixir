# `Miosa.Admin`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/admin.ex#L1)

Admin surface — `/api/v1/admin/*`.

Requires an admin credential: a `msk_a_*` / `msk_p_*` API key or an admin
JWT. Calls from a user-role credential return `{:error, %Miosa.Error{status: 403}}`.

For endpoints not covered by the typed helpers below, use `request/5`
which accepts an arbitrary method + path.

## Example

    client = Miosa.client("msk_a_...")

    {:ok, _} = Miosa.Admin.grant_credits(client, "tenant-uuid", 1000, "goodwill")
    {:ok, users} = Miosa.Admin.list_users(client, limit: 50, status: "active")
    {:ok, _} = Miosa.Admin.change_tenant_plan(client, "tenant-uuid", "pro")

# `result`

```elixir
@type result() :: {:ok, map()} | {:error, Miosa.Error.t()}
```

# `api_key_stats`

```elixir
@spec api_key_stats(Miosa.Client.t()) :: result()
```

# `audit_log`

```elixir
@spec audit_log(
  Miosa.Client.t(),
  keyword()
) :: result()
```

Read the platform audit log.

Options: `:limit`, `:cursor`.

# `ban_user`

```elixir
@spec ban_user(Miosa.Client.t(), String.t(), String.t(), keyword()) :: result()
```

# `billing_summary`

```elixir
@spec billing_summary(Miosa.Client.t()) :: result()
```

# `bulk_revoke_api_keys`

```elixir
@spec bulk_revoke_api_keys(Miosa.Client.t(), [String.t()]) :: result()
```

# `bulk_user_action`

```elixir
@spec bulk_user_action(Miosa.Client.t(), [String.t()], String.t(), keyword()) ::
  result()
```

# `change_tenant_plan`

```elixir
@spec change_tenant_plan(Miosa.Client.t(), String.t(), String.t(), keyword()) ::
  result()
```

# `change_user_role`

```elixir
@spec change_user_role(Miosa.Client.t(), String.t(), String.t()) :: result()
```

# `create_api_key`

```elixir
@spec create_api_key(
  Miosa.Client.t(),
  keyword()
) :: result()
```

Create an API key on behalf of a tenant/user.

Required options: `:name`, `:tenant_id`, `:user_id`.
Optional: `:key_type` (default `"user"`), `:purpose` (default `"api"`),
`:rate_limit_rpm`, `:expires_at`, `:allowed_ips`.

# `dashboard`

```elixir
@spec dashboard(Miosa.Client.t()) :: result()
```

# `deduct_credits`

```elixir
@spec deduct_credits(Miosa.Client.t(), String.t(), integer(), String.t()) :: result()
```

# `delete_computer`

```elixir
@spec delete_computer(Miosa.Client.t(), String.t()) :: result()
```

# `delete_tenant`

```elixir
@spec delete_tenant(Miosa.Client.t(), String.t()) :: result()
```

# `delete_user`

```elixir
@spec delete_user(Miosa.Client.t(), String.t()) :: result()
```

# `detailed_health`

```elixir
@spec detailed_health(Miosa.Client.t()) :: result()
```

# `force_logout`

```elixir
@spec force_logout(Miosa.Client.t(), String.t()) :: result()
```

# `get_user`

```elixir
@spec get_user(Miosa.Client.t(), String.t()) :: result()
```

# `grant_credits`

```elixir
@spec grant_credits(Miosa.Client.t(), String.t(), integer(), String.t(), keyword()) ::
  result()
```

# `list_api_keys`

```elixir
@spec list_api_keys(
  Miosa.Client.t(),
  keyword()
) :: result()
```

List API keys across tenants.

Options: `:limit`, `:cursor`, `:tenant_id`, `:status` (`"active" | "revoked" | "expired"`).

# `list_computers`

```elixir
@spec list_computers(
  Miosa.Client.t(),
  keyword()
) :: result()
```

List all computers across tenants.

Options: `:limit`, `:cursor`, `:status`, `:tenant_id`.

# `list_optimal_models`

```elixir
@spec list_optimal_models(Miosa.Client.t()) :: result()
```

# `list_tenants`

```elixir
@spec list_tenants(
  Miosa.Client.t(),
  keyword()
) :: result()
```

# `list_users`

```elixir
@spec list_users(
  Miosa.Client.t(),
  keyword()
) :: result()
```

List users.

Options: `:limit`, `:cursor`, `:q`, `:status` (`"active" | "suspended" | "deleted"`).

# `optimal_status`

```elixir
@spec optimal_status(Miosa.Client.t()) :: result()
```

# `purge_stale_computers`

```elixir
@spec purge_stale_computers(Miosa.Client.t()) :: result()
```

# `refund_credits`

```elixir
@spec refund_credits(Miosa.Client.t(), String.t(), integer(), String.t(), keyword()) ::
  result()
```

# `request`

```elixir
@spec request(Miosa.Client.t(), atom(), String.t(), map() | nil, keyword()) ::
  result()
```

Call any admin endpoint directly.

`method` is one of `:get`, `:post`, `:put`, `:patch`, `:delete`.
`path` is relative to `/api/v1` and should include the `/admin` prefix.

# `restart_computer`

```elixir
@spec restart_computer(Miosa.Client.t(), String.t()) :: result()
```

# `resume_computer`

```elixir
@spec resume_computer(Miosa.Client.t(), String.t()) :: result()
```

# `revoke_api_key`

```elixir
@spec revoke_api_key(Miosa.Client.t(), String.t()) :: result()
```

# `stats`

```elixir
@spec stats(Miosa.Client.t()) :: result()
```

# `suspend_computer`

```elixir
@spec suspend_computer(Miosa.Client.t(), String.t()) :: result()
```

# `suspend_tenant`

```elixir
@spec suspend_tenant(Miosa.Client.t(), String.t(), keyword()) :: result()
```

# `suspend_user`

```elixir
@spec suspend_user(Miosa.Client.t(), String.t(), keyword()) :: result()
```

# `switch_optimal_model`

```elixir
@spec switch_optimal_model(Miosa.Client.t(), String.t()) :: result()
```

# `tenant_balance`

```elixir
@spec tenant_balance(Miosa.Client.t(), String.t()) :: result()
```

# `tenant_credit_history`

```elixir
@spec tenant_credit_history(Miosa.Client.t(), String.t(), keyword()) :: result()
```

# `tenant_detail`

```elixir
@spec tenant_detail(Miosa.Client.t(), String.t()) :: result()
```

# `unban_user`

```elixir
@spec unban_user(Miosa.Client.t(), String.t()) :: result()
```

# `unsuspend_tenant`

```elixir
@spec unsuspend_tenant(Miosa.Client.t(), String.t()) :: result()
```

# `unsuspend_user`

```elixir
@spec unsuspend_user(Miosa.Client.t(), String.t()) :: result()
```

# `update_user`

```elixir
@spec update_user(Miosa.Client.t(), String.t(), map()) :: result()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
