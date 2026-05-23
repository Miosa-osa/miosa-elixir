defmodule Miosa.Admin do
  @moduledoc """
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

  """

  alias Miosa.Client

  @type result :: {:ok, map()} | {:error, Miosa.Error.t()}

  # ── Escape hatch ────────────────────────────────────────────────────────────

  @doc """
  Call any admin endpoint directly.

  `method` is one of `:get`, `:post`, `:put`, `:patch`, `:delete`.
  `path` is relative to `/api/v1` and should include the `/admin` prefix.
  """
  @spec request(Client.t(), atom(), String.t(), map() | nil, keyword()) :: result
  def request(client, method, path, body \\ nil, opts \\ [])

  def request(client, :get, path, _body, opts), do: Client.get(client, path, opts)
  def request(client, :post, path, body, opts), do: Client.post(client, path, body, opts)
  def request(client, :put, path, body, opts), do: Client.put(client, path, body, opts)
  def request(client, :patch, path, body, opts), do: Client.patch(client, path, body, opts)
  def request(client, :delete, path, _body, opts), do: Client.delete(client, path, opts)

  # ── Overview ────────────────────────────────────────────────────────────────

  @spec dashboard(Client.t()) :: result
  def dashboard(client), do: Client.get(client, "/admin/dashboard")

  @spec stats(Client.t()) :: result
  def stats(client), do: Client.get(client, "/admin/stats")

  @doc """
  Read the platform audit log.

  Options: `:limit`, `:cursor`.
  """
  @spec audit_log(Client.t(), keyword()) :: result
  def audit_log(client, opts \\ []) do
    Client.get(client, "/admin/audit-log", params: pick(opts, [:limit, :cursor]))
  end

  @spec billing_summary(Client.t()) :: result
  def billing_summary(client), do: Client.get(client, "/admin/billing")

  @spec detailed_health(Client.t()) :: result
  def detailed_health(client), do: Client.get(client, "/admin/health/detailed")

  # ── Credits ─────────────────────────────────────────────────────────────────

  @spec grant_credits(Client.t(), String.t(), integer(), String.t(), keyword()) :: result
  def grant_credits(client, tenant_id, amount, description, opts \\ [])
      when is_integer(amount) and amount > 0 do
    body =
      %{tenant_id: tenant_id, amount: amount, description: description}
      |> maybe_put(:expires_at, Keyword.get(opts, :expires_at))

    Client.post(client, "/admin/credits/grant", body)
  end

  @spec deduct_credits(Client.t(), String.t(), integer(), String.t()) :: result
  def deduct_credits(client, tenant_id, amount, description)
      when is_integer(amount) and amount > 0 do
    Client.post(client, "/admin/credits/deduct", %{
      tenant_id: tenant_id,
      amount: amount,
      description: description
    })
  end

  @spec refund_credits(Client.t(), String.t(), integer(), String.t(), keyword()) :: result
  def refund_credits(client, tenant_id, amount, description, opts \\ []) do
    body =
      %{tenant_id: tenant_id, amount: amount, description: description}
      |> maybe_put(:transaction_id, Keyword.get(opts, :transaction_id))

    Client.post(client, "/admin/credits/refund", body)
  end

  @spec tenant_balance(Client.t(), String.t()) :: result
  def tenant_balance(client, tenant_id) do
    Client.get(client, "/admin/credits/#{tenant_id}/balance")
  end

  @spec tenant_credit_history(Client.t(), String.t(), keyword()) :: result
  def tenant_credit_history(client, tenant_id, opts \\ []) do
    Client.get(client, "/admin/credits/#{tenant_id}/history",
      params: pick(opts, [:limit, :cursor])
    )
  end

  # ── Users ───────────────────────────────────────────────────────────────────

  @doc """
  List users.

  Options: `:limit`, `:cursor`, `:q`, `:status` (`"active" | "suspended" | "deleted"`).
  """
  @spec list_users(Client.t(), keyword()) :: result
  def list_users(client, opts \\ []) do
    Client.get(client, "/admin/users", params: pick(opts, [:limit, :cursor, :q, :status]))
  end

  @spec get_user(Client.t(), String.t()) :: result
  def get_user(client, user_id), do: Client.get(client, "/admin/users/#{user_id}")

  @spec update_user(Client.t(), String.t(), map()) :: result
  def update_user(client, user_id, attrs) when is_map(attrs) do
    Client.put(client, "/admin/users/#{user_id}", attrs)
  end

  @spec delete_user(Client.t(), String.t()) :: result
  def delete_user(client, user_id), do: Client.delete(client, "/admin/users/#{user_id}")

  @spec change_user_role(Client.t(), String.t(), String.t()) :: result
  def change_user_role(client, user_id, role) when role in ~w(user admin owner super_admin) do
    Client.post(client, "/admin/users/#{user_id}/role", %{role: role})
  end

  @spec force_logout(Client.t(), String.t()) :: result
  def force_logout(client, user_id) do
    Client.post(client, "/admin/users/#{user_id}/force-logout", nil)
  end

  @spec suspend_user(Client.t(), String.t(), keyword()) :: result
  def suspend_user(client, user_id, opts \\ []) do
    body = maybe_put(%{}, :reason, Keyword.get(opts, :reason))
    Client.post(client, "/admin/users/#{user_id}/suspend", if(body == %{}, do: nil, else: body))
  end

  @spec unsuspend_user(Client.t(), String.t()) :: result
  def unsuspend_user(client, user_id) do
    Client.post(client, "/admin/users/#{user_id}/unsuspend", nil)
  end

  @spec ban_user(Client.t(), String.t(), String.t(), keyword()) :: result
  def ban_user(client, user_id, reason, opts \\ []) do
    body = maybe_put(%{reason: reason}, :expires_at, Keyword.get(opts, :expires_at))
    Client.post(client, "/admin/users/#{user_id}/ban", body)
  end

  @spec unban_user(Client.t(), String.t()) :: result
  def unban_user(client, user_id) do
    Client.post(client, "/admin/users/#{user_id}/unban", nil)
  end

  @spec bulk_user_action(Client.t(), [String.t()], String.t(), keyword()) :: result
  def bulk_user_action(client, user_ids, action, opts \\ [])
      when is_list(user_ids) and action in ~w(suspend unsuspend delete tag notify) do
    body =
      %{user_ids: user_ids, action: action}
      |> maybe_put(:params, Keyword.get(opts, :params))

    Client.post(client, "/admin/users/bulk", body)
  end

  # ── Tenants ─────────────────────────────────────────────────────────────────

  @spec list_tenants(Client.t(), keyword()) :: result
  def list_tenants(client, opts \\ []) do
    Client.get(client, "/admin/tenants", params: pick(opts, [:limit, :cursor, :q]))
  end

  @spec tenant_detail(Client.t(), String.t()) :: result
  def tenant_detail(client, tenant_id) do
    Client.get(client, "/admin/tenants/#{tenant_id}/detail")
  end

  @spec suspend_tenant(Client.t(), String.t(), keyword()) :: result
  def suspend_tenant(client, tenant_id, opts \\ []) do
    body = maybe_put(%{}, :reason, Keyword.get(opts, :reason))

    Client.post(
      client,
      "/admin/tenants/#{tenant_id}/suspend",
      if(body == %{}, do: nil, else: body)
    )
  end

  @spec unsuspend_tenant(Client.t(), String.t()) :: result
  def unsuspend_tenant(client, tenant_id) do
    Client.post(client, "/admin/tenants/#{tenant_id}/unsuspend", nil)
  end

  @spec change_tenant_plan(Client.t(), String.t(), String.t(), keyword()) :: result
  def change_tenant_plan(client, tenant_id, plan, opts \\ [])
      when plan in ~w(free starter pro scale) do
    body = %{plan: plan, prorate: Keyword.get(opts, :prorate, true)}
    Client.post(client, "/admin/tenants/#{tenant_id}/plan", body)
  end

  @spec delete_tenant(Client.t(), String.t()) :: result
  def delete_tenant(client, tenant_id) do
    Client.delete(client, "/admin/tenants/#{tenant_id}")
  end

  # ── Computers ───────────────────────────────────────────────────────────────

  @doc """
  List all computers across tenants.

  Options: `:limit`, `:cursor`, `:status`, `:tenant_id`.
  """
  @spec list_computers(Client.t(), keyword()) :: result
  def list_computers(client, opts \\ []) do
    Client.get(client, "/admin/computers",
      params: pick(opts, [:limit, :cursor, :status, :tenant_id])
    )
  end

  @spec delete_computer(Client.t(), String.t()) :: result
  def delete_computer(client, computer_id) do
    Client.delete(client, "/admin/computers/#{computer_id}")
  end

  @spec suspend_computer(Client.t(), String.t()) :: result
  def suspend_computer(client, computer_id) do
    Client.post(client, "/admin/computers/#{computer_id}/suspend", nil)
  end

  @spec resume_computer(Client.t(), String.t()) :: result
  def resume_computer(client, computer_id) do
    Client.post(client, "/admin/computers/#{computer_id}/resume", nil)
  end

  @spec restart_computer(Client.t(), String.t()) :: result
  def restart_computer(client, computer_id) do
    Client.post(client, "/admin/computers/#{computer_id}/restart", nil)
  end

  @spec purge_stale_computers(Client.t()) :: result
  def purge_stale_computers(client) do
    Client.post(client, "/admin/computers/purge-stale", nil)
  end

  # ── API Keys ────────────────────────────────────────────────────────────────

  @doc """
  List API keys across tenants.

  Options: `:limit`, `:cursor`, `:tenant_id`, `:status` (`"active" | "revoked" | "expired"`).
  """
  @spec list_api_keys(Client.t(), keyword()) :: result
  def list_api_keys(client, opts \\ []) do
    Client.get(client, "/admin/api-keys",
      params: pick(opts, [:limit, :cursor, :tenant_id, :status])
    )
  end

  @doc """
  Create an API key on behalf of a tenant/user.

  Required options: `:name`, `:tenant_id`, `:user_id`.
  Optional: `:key_type` (default `"user"`), `:purpose` (default `"api"`),
  `:rate_limit_rpm`, `:expires_at`, `:allowed_ips`.
  """
  @spec create_api_key(Client.t(), keyword()) :: result
  def create_api_key(client, opts) do
    body =
      %{
        name: Keyword.fetch!(opts, :name),
        tenant_id: Keyword.fetch!(opts, :tenant_id),
        user_id: Keyword.fetch!(opts, :user_id),
        key_type: Keyword.get(opts, :key_type, "user"),
        purpose: Keyword.get(opts, :purpose, "api")
      }
      |> maybe_put(:rate_limit_rpm, Keyword.get(opts, :rate_limit_rpm))
      |> maybe_put(:expires_at, Keyword.get(opts, :expires_at))
      |> maybe_put(:allowed_ips, Keyword.get(opts, :allowed_ips))

    Client.post(client, "/admin/api-keys", body)
  end

  @spec api_key_stats(Client.t()) :: result
  def api_key_stats(client), do: Client.get(client, "/admin/api-keys/stats")

  @spec bulk_revoke_api_keys(Client.t(), [String.t()]) :: result
  def bulk_revoke_api_keys(client, key_ids) when is_list(key_ids) do
    Client.post(client, "/admin/api-keys/bulk-revoke", %{key_ids: key_ids})
  end

  @spec revoke_api_key(Client.t(), String.t()) :: result
  def revoke_api_key(client, key_id) do
    Client.delete(client, "/admin/api-keys/#{key_id}")
  end

  # ── Optimal ─────────────────────────────────────────────────────────────────

  @spec optimal_status(Client.t()) :: result
  def optimal_status(client), do: Client.get(client, "/admin/optimal/status")

  @spec list_optimal_models(Client.t()) :: result
  def list_optimal_models(client), do: Client.get(client, "/admin/optimal/models")

  @spec switch_optimal_model(Client.t(), String.t()) :: result
  def switch_optimal_model(client, model_id) do
    Client.post(client, "/admin/optimal/models/switch", %{model_id: model_id})
  end

  # ── Helpers ─────────────────────────────────────────────────────────────────

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp pick(opts, keys) do
    opts
    |> Keyword.take(keys)
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
  end
end
