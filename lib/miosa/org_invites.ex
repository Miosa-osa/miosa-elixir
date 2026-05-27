defmodule Miosa.OrgInvites do
  @moduledoc """
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

  """

  alias Miosa.Client

  # ── create/4 ─────────────────────────────────────────────────────────────────

  @doc """
  Creates an org invite and dispatches the invite email.

  The response includes an `invite_url` that is host-aware: on white-label
  tenants it uses the tenant's custom domain.

  Requires `admin` or `owner` role in the tenant.

  ## Example

      {:ok, created} = Miosa.OrgInvites.create(client, tenant_id, "bob@example.com", "member")
      IO.puts("invite URL: \#{created["invite_url"]}")

  """
  @spec create(Client.t(), String.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, term()}
  def create(%Client{} = client, tenant_id, email, role \\ "member") do
    body = %{"email" => email, "role" => role}

    case Client.post(client, "/tenants/#{tenant_id}/invites", body) do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, data} -> {:ok, data}
      {:error, _} = err -> err
    end
  end

  # ── list/2 ───────────────────────────────────────────────────────────────────

  @doc """
  Lists all pending org invites.

  Requires `admin` or `owner` role.

  ## Example

      {:ok, invites} = Miosa.OrgInvites.list(client, tenant_id)

  """
  @spec list(Client.t(), String.t()) :: {:ok, [map()]} | {:error, term()}
  def list(%Client{} = client, tenant_id) do
    case Client.get(client, "/tenants/#{tenant_id}/invites") do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, data} when is_list(data) -> {:ok, data}
      {:error, _} = err -> err
    end
  end

  # ── revoke/3 ─────────────────────────────────────────────────────────────────

  @doc """
  Revokes a pending org invite.

  Returns `{:error, :already_accepted}` (via server 409) when the invite was
  already legitimately accepted.

  Requires `admin` or `owner` role.

  ## Example

      {:ok, _} = Miosa.OrgInvites.revoke(client, tenant_id, invite_id)

  """
  @spec revoke(Client.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, term()}
  def revoke(%Client{} = client, tenant_id, invite_id) do
    Client.delete(client, "/tenants/#{tenant_id}/invites/#{invite_id}")
  end

  # ── preview/2 ────────────────────────────────────────────────────────────────

  @doc """
  Returns a public preview of the org invite by token (no auth required).

  Use this to render the pre-auth invite landing page. Returns
  `{:error, :not_found}` when the token is unknown or has been revoked.

  ## Example

      {:ok, preview} = Miosa.OrgInvites.preview(client, token)
      IO.inspect(preview["tenant_name"])

  """
  @spec preview(Client.t(), String.t()) :: {:ok, map()} | {:error, :not_found | term()}
  def preview(%Client{} = client, token) do
    case Client.get(client, "/invites/#{token}") do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, data} -> {:ok, data}
      {:error, _} = err -> err
    end
  end

  # ── accept/2 ─────────────────────────────────────────────────────────────────

  @doc """
  Accepts an org invite on behalf of the authenticated user.

  The caller's API key email must match the invite email (case-insensitive).
  On success inserts a `tenant_members` row.

  Error atoms (from server response):
    - `:invalid_token` (400) — token not found or expired.
    - `:email_mismatch` (422) — session email differs from invite email.

  ## Example

      {:ok, result} = Miosa.OrgInvites.accept(client, token)
      IO.puts("joined org: \#{result["tenant_id"]}")

  """
  @spec accept(Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def accept(%Client{} = client, token) do
    Client.post(client, "/invites/#{token}/accept", %{})
  end
end
