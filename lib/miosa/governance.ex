defmodule Miosa.Governance do
  @moduledoc """
  Phase 6 admin governance — policy, members, workspaces, bulk ops, billing,
  impersonation, and scoped API keys.

  All functions follow the same `{:ok, result} | {:error, Miosa.Error.t()}`
  convention as the rest of the SDK.

  ## Policy

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

      {:ok, policy} = Miosa.Governance.get_tenant_policy(client)
      {:ok, _} = Miosa.Governance.set_tenant_policy(client, %{quotas: %{max_sandboxes: 5}})
      :ok = Miosa.Governance.delete_tenant_policy(client)

  ## Effective policy (resolved with sources)

      {:ok, eff} = Miosa.Governance.get_effective_policy(client, "alice-42")
      idle = get_in(eff, ["lifecycle", "default_idle_timeout_sec"])
      # %{"value" => 600, "source" => "user"}

  ## Bulk ops

      {:ok, job} = Miosa.Governance.bulk_sandboxes_pause(client, ids: ["sbx_1", "sbx_2"])
      {:ok, status} = Miosa.Governance.get_bulk_job(client, job["job_id"])

  """

  alias Miosa.Client

  # ── Helpers ──────────────────────────────────────────────────────────────────

  defp unwrap({:ok, %{"data" => data}}), do: {:ok, data}
  defp unwrap({:ok, body}), do: {:ok, body}
  defp unwrap(err), do: err

  defp build_query([]), do: ""
  defp build_query(params) do
    "?" <>
      (params
       |> Enum.reject(fn {_k, v} -> is_nil(v) end)
       |> Enum.map(fn {k, v} -> "#{k}=#{URI.encode_www_form(to_string(v))}" end)
       |> Enum.join("&"))
  end

  # ── Tenant policy ─────────────────────────────────────────────────────────────

  @doc "GET /api/v1/tenant/policy"
  @spec get_tenant_policy(Client.t()) :: Client.result(map())
  def get_tenant_policy(client) do
    unwrap(Client.get(client, "/tenant/policy"))
  end

  @doc "PUT /api/v1/tenant/policy"
  @spec set_tenant_policy(Client.t(), map()) :: Client.result(map())
  def set_tenant_policy(client, policy) when is_map(policy) do
    unwrap(Client.put(client, "/tenant/policy", policy))
  end

  @doc "DELETE /api/v1/tenant/policy"
  @spec delete_tenant_policy(Client.t()) :: {:ok, map()} | {:error, Miosa.Error.t()}
  def delete_tenant_policy(client) do
    Client.delete(client, "/tenant/policy")
  end

  # ── Tenant members ────────────────────────────────────────────────────────────

  @doc "GET /api/v1/tenant/members"
  @spec list_tenant_members(Client.t()) :: Client.result(list())
  def list_tenant_members(client) do
    case Client.get(client, "/tenant/members") do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, body} -> {:ok, Map.get(body, "members", [])}
      err -> err
    end
  end

  @doc "POST /api/v1/tenant/members — invite by email + role."
  @spec invite_tenant_member(Client.t(), String.t(), String.t()) :: Client.result(map())
  def invite_tenant_member(client, email, role) when is_binary(email) and is_binary(role) do
    unwrap(Client.post(client, "/tenant/members", %{"email" => email, "role" => role}))
  end

  @doc "PATCH /api/v1/tenant/members/{member_id}/role"
  @spec update_tenant_member_role(Client.t(), String.t(), String.t()) :: Client.result(map())
  def update_tenant_member_role(client, member_id, role) do
    unwrap(Client.patch(client, "/tenant/members/#{member_id}/role", %{"role" => role}))
  end

  @doc "DELETE /api/v1/tenant/members/{member_id}"
  @spec remove_tenant_member(Client.t(), String.t()) :: {:ok, map()} | {:error, Miosa.Error.t()}
  def remove_tenant_member(client, member_id) do
    Client.delete(client, "/tenant/members/#{member_id}")
  end

  @doc "POST /api/v1/tenant/transfer-ownership"
  @spec transfer_tenant_ownership(Client.t(), String.t()) :: Client.result(map())
  def transfer_tenant_ownership(client, new_owner_user_id) do
    unwrap(Client.post(client, "/tenant/transfer-ownership", %{"new_owner_user_id" => new_owner_user_id}))
  end

  # ── Tenant events stream ──────────────────────────────────────────────────────

  @doc """
  Returns a `Stream` that yields tenant admin events from SSE.

  ## Options

    * `:types` — List of event type patterns, e.g. `["sandbox.*", "member.*"]`.
    * `:scope` — `"all"`, `"workspace:{id}"`, or `"external_user:{id}"`.
    * `:timeout` — Per-event receive timeout in milliseconds. Default: `300_000`.

  ## Example

      stream = Miosa.Governance.stream_tenant_events(client,
        types: ["sandbox.*", "policy.*"],
        scope: "all"
      )
      Enum.each(stream, fn event -> IO.inspect(event) end)
  """
  @spec stream_tenant_events(Client.t(), keyword()) :: Enumerable.t()
  def stream_tenant_events(%Client{} = client, opts \\ []) do
    types = Keyword.get(opts, :types, [])
    scope = Keyword.get(opts, :scope)
    timeout = Keyword.get(opts, :timeout, 300_000)

    params =
      []
      |> then(fn p -> if types != [], do: [{:types, Enum.join(types, ",")} | p], else: p end)
      |> then(fn p -> if scope, do: [{:scope, scope} | p], else: p end)

    path = "/tenant/events/stream" <> build_query(params)

    Stream.resource(
      fn -> Client.stream_sse(client, path, timeout: timeout) end,
      fn
        {:error, _reason} = err ->
          {[], err}

        stream_ref ->
          receive do
            {:sse_event, ^stream_ref, event} ->
              {[event], stream_ref}

            {:sse_done, ^stream_ref} ->
              {:halt, stream_ref}

            {:sse_error, ^stream_ref, reason} ->
              {:halt, {:error, reason}}
          after
            timeout ->
              {:halt, stream_ref}
          end
      end,
      fn _ -> :ok end
    )
  end

  # ── Workspace policy ──────────────────────────────────────────────────────────

  @doc "GET /api/v1/workspaces/{id}/policy"
  @spec get_workspace_policy(Client.t(), String.t()) :: Client.result(map())
  def get_workspace_policy(client, workspace_id) do
    unwrap(Client.get(client, "/workspaces/#{workspace_id}/policy"))
  end

  @doc "PUT /api/v1/workspaces/{id}/policy"
  @spec set_workspace_policy(Client.t(), String.t(), map()) :: Client.result(map())
  def set_workspace_policy(client, workspace_id, policy) when is_map(policy) do
    unwrap(Client.put(client, "/workspaces/#{workspace_id}/policy", policy))
  end

  @doc "DELETE /api/v1/workspaces/{id}/policy"
  @spec delete_workspace_policy(Client.t(), String.t()) :: {:ok, map()} | {:error, Miosa.Error.t()}
  def delete_workspace_policy(client, workspace_id) do
    Client.delete(client, "/workspaces/#{workspace_id}/policy")
  end

  # ── Workspace members ─────────────────────────────────────────────────────────

  @doc "GET /api/v1/workspaces/{id}/members"
  @spec list_workspace_members(Client.t(), String.t()) :: Client.result(list())
  def list_workspace_members(client, workspace_id) do
    case Client.get(client, "/workspaces/#{workspace_id}/members") do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, body} -> {:ok, Map.get(body, "members", [])}
      err -> err
    end
  end

  @doc "POST /api/v1/workspaces/{id}/members"
  @spec invite_workspace_member(Client.t(), String.t(), String.t(), String.t()) :: Client.result(map())
  def invite_workspace_member(client, workspace_id, email, role) do
    unwrap(Client.post(client, "/workspaces/#{workspace_id}/members", %{"email" => email, "role" => role}))
  end

  @doc "PATCH /api/v1/workspaces/{id}/members/{member_id}/role"
  @spec update_workspace_member_role(Client.t(), String.t(), String.t(), String.t()) :: Client.result(map())
  def update_workspace_member_role(client, workspace_id, member_id, role) do
    unwrap(Client.patch(client, "/workspaces/#{workspace_id}/members/#{member_id}/role", %{"role" => role}))
  end

  @doc "DELETE /api/v1/workspaces/{id}/members/{member_id}"
  @spec remove_workspace_member(Client.t(), String.t(), String.t()) :: {:ok, map()} | {:error, Miosa.Error.t()}
  def remove_workspace_member(client, workspace_id, member_id) do
    Client.delete(client, "/workspaces/#{workspace_id}/members/#{member_id}")
  end

  # ── Workspace transfer ────────────────────────────────────────────────────────

  @doc "POST /api/v1/workspaces/{id}/transfer"
  @spec transfer_workspace_resources(Client.t(), String.t(), list(String.t()), String.t()) :: Client.result(map())
  def transfer_workspace_resources(client, workspace_id, resource_ids, target_workspace_id) do
    body = %{"resource_ids" => resource_ids, "target_workspace_id" => target_workspace_id}
    unwrap(Client.post(client, "/workspaces/#{workspace_id}/transfer", body))
  end

  # ── External user policy ──────────────────────────────────────────────────────

  @doc "GET /api/v1/external-users/{id}/policy"
  @spec get_external_user_policy(Client.t(), String.t()) :: Client.result(map())
  def get_external_user_policy(client, external_user_id) do
    unwrap(Client.get(client, "/external-users/#{external_user_id}/policy"))
  end

  @doc "PUT /api/v1/external-users/{id}/policy"
  @spec set_external_user_policy(Client.t(), String.t(), map()) :: Client.result(map())
  def set_external_user_policy(client, external_user_id, policy) when is_map(policy) do
    unwrap(Client.put(client, "/external-users/#{external_user_id}/policy", policy))
  end

  @doc "DELETE /api/v1/external-users/{id}/policy"
  @spec delete_external_user_policy(Client.t(), String.t()) :: {:ok, map()} | {:error, Miosa.Error.t()}
  def delete_external_user_policy(client, external_user_id) do
    Client.delete(client, "/external-users/#{external_user_id}/policy")
  end

  @doc """
  GET /api/v1/external-users/{id}/effective-policy

  Returns the fully resolved policy for the external user, with each field
  annotated with its source tier: `"user"`, `"workspace"`, `"tenant"`, or `"platform"`.

  ## Example

      {:ok, eff} = Miosa.Governance.get_effective_policy(client, "alice-42")
      %{"value" => 600, "source" => "user"} =
        get_in(eff, ["lifecycle", "default_idle_timeout_sec"])
  """
  @spec get_effective_policy(Client.t(), String.t()) :: Client.result(map())
  def get_effective_policy(client, external_user_id) do
    case Client.get(client, "/external-users/#{external_user_id}/effective-policy") do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, body} -> {:ok, body}
      err -> err
    end
  end

  # ── Bulk ops ──────────────────────────────────────────────────────────────────

  defp bulk_body(ids: ids), do: %{"ids" => ids}
  defp bulk_body(filter: filter), do: %{"filter" => filter}

  @doc "POST /api/v1/bulk/sandboxes/pause — opts: `[ids: [...]]` or `[filter: %{}]`"
  @spec bulk_sandboxes_pause(Client.t(), keyword()) :: Client.result(map())
  def bulk_sandboxes_pause(client, opts) do
    Client.post(client, "/bulk/sandboxes/pause", bulk_body(opts))
  end

  @doc "POST /api/v1/bulk/sandboxes/resume"
  @spec bulk_sandboxes_resume(Client.t(), keyword()) :: Client.result(map())
  def bulk_sandboxes_resume(client, opts) do
    Client.post(client, "/bulk/sandboxes/resume", bulk_body(opts))
  end

  @doc "POST /api/v1/bulk/sandboxes/destroy"
  @spec bulk_sandboxes_destroy(Client.t(), keyword()) :: Client.result(map())
  def bulk_sandboxes_destroy(client, opts) do
    Client.post(client, "/bulk/sandboxes/destroy", bulk_body(opts))
  end

  @doc """
  POST /api/v1/bulk/policy/apply

  ## Options

    * `:tier` — Required. `"external_user"`, `"workspace"`, or `"tenant"`.
    * `:ids` — List of resource IDs.
    * `:filter` — Map of filter params (alternative to `:ids`).
    * `:policy` — Required. Policy map to apply.
  """
  @spec bulk_apply_policy(Client.t(), keyword()) :: Client.result(map())
  def bulk_apply_policy(client, opts) do
    tier = Keyword.fetch!(opts, :tier)
    policy = Keyword.fetch!(opts, :policy)

    body =
      %{"tier" => tier, "policy" => policy}
      |> then(fn b ->
        cond do
          ids = Keyword.get(opts, :ids) -> Map.put(b, "ids", ids)
          filter = Keyword.get(opts, :filter) -> Map.put(b, "filter", filter)
          true -> b
        end
      end)

    Client.post(client, "/bulk/policy/apply", body)
  end

  @doc "GET /api/v1/bulk/jobs/{job_id} — poll async job status."
  @spec get_bulk_job(Client.t(), String.t()) :: Client.result(map())
  def get_bulk_job(client, job_id) do
    unwrap(Client.get(client, "/bulk/jobs/#{job_id}"))
  end

  # ── Scoped API keys ───────────────────────────────────────────────────────────

  @doc """
  POST /api/v1/api-keys/scoped — L2 delegation token bound to one external user.

  ## Options

    * `:external_user_id` — Required.
    * `:scopes` — Required list of scope strings.
    * `:expires_at` — Optional ISO 8601 expiry timestamp.
  """
  @spec create_scoped_api_key(Client.t(), keyword()) :: Client.result(map())
  def create_scoped_api_key(client, opts) do
    external_user_id = Keyword.fetch!(opts, :external_user_id)
    scopes = Keyword.fetch!(opts, :scopes)
    expires_at = Keyword.get(opts, :expires_at)

    body =
      %{"external_user_id" => external_user_id, "scopes" => scopes}
      |> then(fn b -> if expires_at, do: Map.put(b, "expires_at", expires_at), else: b end)

    unwrap(Client.post(client, "/api-keys/scoped", body))
  end

  # ── Impersonation ─────────────────────────────────────────────────────────────

  @doc """
  POST /api/v1/admin/impersonate — returns `%{"token" => "msi_...", "expires_at" => ...}`.

  The `msi_` token acts as the external user for support/debugging. It is
  audit-logged with `actor.impersonating: true`.

  ## Options

    * `:ttl_sec` — Token lifetime in seconds. Default: `3600`.
  """
  @spec impersonate(Client.t(), String.t(), keyword()) :: Client.result(map())
  def impersonate(client, external_user_id, opts \\ []) do
    ttl_sec = Keyword.get(opts, :ttl_sec, 3600)
    body = %{"external_user_id" => external_user_id, "ttl_sec" => ttl_sec}
    Client.post(client, "/admin/impersonate", body)
  end

  # ── Billing ───────────────────────────────────────────────────────────────────

  @doc "GET /api/v1/billing/invoices"
  @spec list_invoices(Client.t(), keyword()) :: Client.result(list())
  def list_invoices(client, opts \\ []) do
    params = Keyword.take(opts, [:limit, :cursor])
    path = "/billing/invoices" <> build_query(params)

    case Client.get(client, path) do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, body} -> {:ok, Map.get(body, "invoices", [])}
      err -> err
    end
  end

  @doc "GET /api/v1/billing/invoices/{id}"
  @spec get_invoice(Client.t(), String.t()) :: Client.result(map())
  def get_invoice(client, invoice_id) do
    unwrap(Client.get(client, "/billing/invoices/#{invoice_id}"))
  end

  @doc "GET /api/v1/billing/payment-methods"
  @spec list_payment_methods(Client.t()) :: Client.result(list())
  def list_payment_methods(client) do
    case Client.get(client, "/billing/payment-methods") do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, body} -> {:ok, Map.get(body, "payment_methods", [])}
      err -> err
    end
  end

  @doc "GET /api/v1/billing/upcoming — next invoice preview."
  @spec get_upcoming_invoice(Client.t()) :: Client.result(map())
  def get_upcoming_invoice(client) do
    unwrap(Client.get(client, "/billing/upcoming"))
  end
end
