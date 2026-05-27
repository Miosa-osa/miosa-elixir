defmodule Miosa.WorkspaceInvites do
  @moduledoc """
  Email invite flow for workspace access.

  Sending an invite to an email that already belongs to a tenant member
  short-circuits to directly adding that user (returns `{:ok, :added, record}`).
  Accepting a workspace invite for an unknown email auto-creates both a
  `tenant_members` and a `workspace_members` row atomically.

  ## Example

      client = Miosa.client("msk_u_...")

      # invite someone new
      {:ok, :invited, invite} = Miosa.WorkspaceInvites.create(client, ws_id, tenant_id, "alice@example.com", "member")

      # or they're already in the org — added directly
      {:ok, :added, member} = Miosa.WorkspaceInvites.create(client, ws_id, tenant_id, "bob@example.com", "member")

      {:ok, invites} = Miosa.WorkspaceInvites.list(client, ws_id)
      {:ok, _}       = Miosa.WorkspaceInvites.revoke(client, ws_id, List.first(invites)["id"])

      {:ok, preview} = Miosa.WorkspaceInvites.preview(client, token)
      unless preview["expired"] do
        {:ok, _} = Miosa.WorkspaceInvites.accept(client, token)
      end

  ## Endpoints

    * `POST   /workspaces/:id/invites`           (auth required)
    * `GET    /workspaces/:id/invites`           (auth required)
    * `DELETE /workspaces/:id/invites/:invite_id` (auth required)
    * `GET    /workspace-invites/:token`          (public, no auth)
    * `POST   /workspace-invites/:token/accept`   (auth required)

  """

  alias Miosa.Client

  # ── create/5 ─────────────────────────────────────────────────────────────────

  @doc """
  Creates a workspace invite or adds a member directly.

  Returns:
    - `{:ok, :invited, invite_map}` — invite created and email dispatched.
    - `{:ok, :added, member_map}`   — email already in org; user added directly.
    - `{:error, reason}`

  ## Example

      {:ok, :invited, invite} = Miosa.WorkspaceInvites.create(client, ws_id, tenant_id, "alice@example.com", "member")

  """
  @spec create(Client.t(), String.t(), String.t(), String.t(), String.t()) ::
          {:ok, :invited | :added, map()} | {:error, term()}
  def create(%Client{} = client, workspace_id, _tenant_id, email, role \\ "member") do
    body = %{"email" => email, "role" => role}

    case Client.post(client, "/workspaces/#{workspace_id}/invites", body) do
      {:ok, %{"data" => data, "type" => "invited"}} -> {:ok, :invited, data}
      {:ok, %{"data" => data, "type" => "added"}} -> {:ok, :added, data}
      {:ok, data} -> {:ok, :invited, data}
      {:error, _} = err -> err
    end
  end

  # ── list/2 ───────────────────────────────────────────────────────────────────

  @doc """
  Lists all pending workspace invites.

  ## Example

      {:ok, invites} = Miosa.WorkspaceInvites.list(client, workspace_id)

  """
  @spec list(Client.t(), String.t()) :: {:ok, [map()]} | {:error, term()}
  def list(%Client{} = client, workspace_id) do
    case Client.get(client, "/workspaces/#{workspace_id}/invites") do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, data} when is_list(data) -> {:ok, data}
      {:error, _} = err -> err
    end
  end

  # ── revoke/3 ─────────────────────────────────────────────────────────────────

  @doc """
  Revokes a pending workspace invite.

  Already-revoked invites are idempotent. Returns `{:error, :already_accepted}`
  (via server 409) when the invite was legitimately accepted.

  ## Example

      {:ok, _} = Miosa.WorkspaceInvites.revoke(client, workspace_id, invite_id)

  """
  @spec revoke(Client.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, term()}
  def revoke(%Client{} = client, workspace_id, invite_id) do
    Client.delete(client, "/workspaces/#{workspace_id}/invites/#{invite_id}")
  end

  # ── preview/2 ────────────────────────────────────────────────────────────────

  @doc """
  Returns a public preview of the invite by token (no auth required).

  Use this to render the invite landing page before prompting the user to
  log in or sign up. Returns `{:error, :not_found}` when the token is unknown
  or has been revoked.

  ## Example

      {:ok, preview} = Miosa.WorkspaceInvites.preview(client, token)
      IO.inspect(preview["workspace_name"])

  """
  @spec preview(Client.t(), String.t()) :: {:ok, map()} | {:error, :not_found | term()}
  def preview(%Client{} = client, token) do
    case Client.get(client, "/workspace-invites/#{token}") do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, data} -> {:ok, data}
      {:error, _} = err -> err
    end
  end

  # ── accept/2 ─────────────────────────────────────────────────────────────────

  @doc """
  Accepts a workspace invite on behalf of the authenticated user.

  The caller's API key email must match the invite email (case-insensitive).

  Error atoms (from server response):
    - `:invalid_token` (404) — token not found.
    - `:expired` (410) — invite TTL elapsed.
    - `:revoked` (409) — invite was revoked.
    - `:already_accepted` (409) — already used.
    - `:email_mismatch` (422) — email in session differs from invite.

  ## Example

      {:ok, result} = Miosa.WorkspaceInvites.accept(client, token)
      IO.puts("joined workspace: \#{result["workspace_id"]}")

  """
  @spec accept(Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def accept(%Client{} = client, token) do
    Client.post(client, "/workspace-invites/#{token}/accept", %{})
  end
end
