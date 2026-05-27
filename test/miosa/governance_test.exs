defmodule Miosa.GovernanceTest do
  use ExUnit.Case, async: true

  alias Miosa.Governance

  setup do
    bypass = Bypass.open()
    client = Miosa.client("msk_u_test", base_url: "http://localhost:#{bypass.port}/api/v1")
    {:ok, bypass: bypass, client: client}
  end

  # ── Tenant policy ─────────────────────────────────────────────────────────────

  describe "get_tenant_policy/1" do
    test "returns policy on 200", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/tenant/policy", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"data" => %{"quotas" => %{"max_sandboxes" => 10}}}))
      end)

      assert {:ok, policy} = Governance.get_tenant_policy(client)
      assert get_in(policy, ["quotas", "max_sandboxes"]) == 10
    end

    test "returns error on 403", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/tenant/policy", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(403, Jason.encode!(%{"error" => %{"code" => "FORBIDDEN"}}))
      end)

      assert {:error, %Miosa.Error{status: 403}} = Governance.get_tenant_policy(client)
    end
  end

  describe "set_tenant_policy/2" do
    test "PUT body is forwarded and response is unwrapped", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "PUT", "/api/v1/tenant/policy", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        %{"quotas" => %{"max_sandboxes" => 5}} = Jason.decode!(body)

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"data" => %{"quotas" => %{"max_sandboxes" => 5}}}))
      end)

      assert {:ok, %{"quotas" => %{"max_sandboxes" => 5}}} =
               Governance.set_tenant_policy(client, %{"quotas" => %{"max_sandboxes" => 5}})
    end
  end

  # ── Tenant members ────────────────────────────────────────────────────────────

  describe "list_tenant_members/1" do
    test "returns member list", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/tenant/members", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"data" => [%{"id" => "m1", "role" => "admin"}]}))
      end)

      assert {:ok, [%{"id" => "m1", "role" => "admin"}]} = Governance.list_tenant_members(client)
    end
  end

  describe "invite_tenant_member/3" do
    test "posts email and role", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/tenant/members", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        %{"email" => "x@y.com", "role" => "developer"} = Jason.decode!(body)

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"data" => %{"id" => "m2", "role" => "developer"}}))
      end)

      assert {:ok, %{"role" => "developer"}} =
               Governance.invite_tenant_member(client, "x@y.com", "developer")
    end
  end

  describe "transfer_tenant_ownership/2" do
    test "posts new_owner_user_id", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/tenant/transfer-ownership", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        %{"new_owner_user_id" => "user_new"} = Jason.decode!(body)

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"data" => %{"transferred" => true}}))
      end)

      assert {:ok, %{"transferred" => true}} =
               Governance.transfer_tenant_ownership(client, "user_new")
    end
  end

  # ── Workspace policy ──────────────────────────────────────────────────────────

  describe "get_workspace_policy/2" do
    test "calls correct path and unwraps data", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/workspaces/ws_1/policy", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"data" => %{"quotas" => %{"max_sandboxes" => 3}}}))
      end)

      assert {:ok, %{"quotas" => %{"max_sandboxes" => 3}}} =
               Governance.get_workspace_policy(client, "ws_1")
    end
  end

  describe "list_workspace_members/2" do
    test "returns member list for workspace", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/workspaces/ws_1/members", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"data" => [%{"id" => "m1", "role" => "developer"}]}))
      end)

      assert {:ok, [%{"role" => "developer"}]} = Governance.list_workspace_members(client, "ws_1")
    end
  end

  describe "transfer_workspace_resources/4" do
    test "posts resource_ids and target_workspace_id", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/workspaces/ws_1/transfer", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        %{"resource_ids" => ["sbx_1"], "target_workspace_id" => "ws_2"} = Jason.decode!(body)

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"data" => %{"transferred" => 1}}))
      end)

      assert {:ok, %{"transferred" => 1}} =
               Governance.transfer_workspace_resources(client, "ws_1", ["sbx_1"], "ws_2")
    end
  end

  # ── External user policy ──────────────────────────────────────────────────────

  describe "get_effective_policy/2" do
    test "returns effective policy with source annotations", %{bypass: bypass, client: client} do
      effective = %{
        "lifecycle" => %{
          "default_idle_timeout_sec" => %{"value" => 600, "source" => "user"},
          "default_timeout_sec" => %{"value" => 86400, "source" => "tenant"}
        },
        "quotas" => %{
          "max_sandboxes" => %{"value" => 5, "source" => "workspace"}
        }
      }

      Bypass.expect_once(bypass, "GET", "/api/v1/external-users/alice/effective-policy", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(effective))
      end)

      assert {:ok, eff} = Governance.get_effective_policy(client, "alice")
      assert get_in(eff, ["lifecycle", "default_idle_timeout_sec", "value"]) == 600
      assert get_in(eff, ["lifecycle", "default_idle_timeout_sec", "source"]) == "user"
      assert get_in(eff, ["quotas", "max_sandboxes", "source"]) == "workspace"
    end
  end

  # ── Bulk ops ──────────────────────────────────────────────────────────────────

  describe "bulk_sandboxes_pause/2" do
    test "posts ids and returns job_id", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/bulk/sandboxes/pause", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        %{"ids" => ["sbx_1", "sbx_2"]} = Jason.decode!(body)

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"queued" => 2, "job_id" => "job_1"}))
      end)

      assert {:ok, %{"job_id" => "job_1", "queued" => 2}} =
               Governance.bulk_sandboxes_pause(client, ids: ["sbx_1", "sbx_2"])
    end
  end

  describe "bulk_apply_policy/2" do
    test "posts tier, ids, and policy", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/bulk/policy/apply", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded["tier"] == "external_user"
        assert decoded["ids"] == ["u1", "u2"]
        assert get_in(decoded, ["policy", "quotas", "max_sandboxes"]) == 3

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"queued" => 2, "job_id" => "job_2"}))
      end)

      assert {:ok, %{"job_id" => "job_2"}} =
               Governance.bulk_apply_policy(client,
                 tier: "external_user",
                 ids: ["u1", "u2"],
                 policy: %{"quotas" => %{"max_sandboxes" => 3}}
               )
    end
  end

  describe "get_bulk_job/2" do
    test "returns job status", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/bulk/jobs/job_1", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"data" => %{"id" => "job_1", "status" => "completed", "processed" => 3}}))
      end)

      assert {:ok, %{"status" => "completed", "processed" => 3}} =
               Governance.get_bulk_job(client, "job_1")
    end
  end

  # ── Scoped API keys ───────────────────────────────────────────────────────────

  describe "create_scoped_api_key/2" do
    test "posts external_user_id and scopes", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/api-keys/scoped", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded["external_user_id"] == "alice-42"
        assert decoded["scopes"] == ["sandboxes:read"]

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"data" => %{"id" => "key_1", "token" => "msk_l2_abc"}}))
      end)

      assert {:ok, %{"token" => "msk_l2_abc"}} =
               Governance.create_scoped_api_key(client,
                 external_user_id: "alice-42",
                 scopes: ["sandboxes:read"]
               )
    end
  end

  # ── Impersonation ─────────────────────────────────────────────────────────────

  describe "impersonate/3" do
    test "posts external_user_id and ttl_sec, returns token", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/admin/impersonate", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        %{"external_user_id" => "alice-42", "ttl_sec" => 1800} = Jason.decode!(body)

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"token" => "msi_abc", "expires_at" => "2026-06-01T00:00:00Z"}))
      end)

      assert {:ok, %{"token" => "msi_abc"}} =
               Governance.impersonate(client, "alice-42", ttl_sec: 1800)
    end

    test "defaults ttl_sec to 3600", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/admin/impersonate", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        %{"ttl_sec" => 3600} = Jason.decode!(body)

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"token" => "msi_xyz"}))
      end)

      assert {:ok, %{"token" => "msi_xyz"}} =
               Governance.impersonate(client, "bob")
    end
  end

  # ── Billing ───────────────────────────────────────────────────────────────────

  describe "list_invoices/1" do
    test "returns invoice list", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/billing/invoices", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"data" => [%{"id" => "inv_1", "amount" => 5000}]}))
      end)

      assert {:ok, [%{"id" => "inv_1"}]} = Governance.list_invoices(client)
    end
  end

  describe "get_upcoming_invoice/1" do
    test "returns upcoming preview", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/billing/upcoming", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"data" => %{"amount" => 1200}}))
      end)

      assert {:ok, %{"amount" => 1200}} = Governance.get_upcoming_invoice(client)
    end
  end
end
