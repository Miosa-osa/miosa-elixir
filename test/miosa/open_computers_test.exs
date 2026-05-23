defmodule Miosa.OpenComputersTest do
  use ExUnit.Case, async: true

  alias Miosa.OpenComputers.{Hosts, Jobs, Tunnels, Agents, Clusters, Secrets}
  alias Miosa.Error

  @host_json %{
    "id" => "host_abc",
    "name" => "my-mac",
    "region" => nil,
    "status" => "online",
    "tenant_id" => "t_1",
    "labels" => %{},
    "created_at" => "2026-01-01T00:00:00Z",
    "updated_at" => "2026-01-01T00:00:00Z"
  }

  @job_json %{
    "id" => "job_1",
    "host_id" => "host_abc",
    "status" => "completed",
    "command" => "npm test",
    "args" => [],
    "env" => [],
    "cwd" => nil,
    "exit_code" => 0,
    "stdout" => "ok",
    "stderr" => "",
    "created_at" => "2026-01-01T00:00:00Z",
    "updated_at" => "2026-01-01T00:00:00Z",
    "completed_at" => "2026-01-01T00:00:01Z"
  }

  @tunnel_json %{
    "id" => "tun_1",
    "host_id" => "host_abc",
    "slug" => "abc123",
    "target_port" => 3000,
    "auth_mode" => "public",
    "public_url" => "https://api.miosa.ai/t/abc123",
    "enabled" => true,
    "created_at" => "2026-01-01T00:00:00Z",
    "updated_at" => "2026-01-01T00:00:00Z"
  }

  @session_json %{
    "id" => "sess_1",
    "host_id" => "host_abc",
    "task" => "run tests",
    "model_id" => nil,
    "status" => "pending",
    "max_turns" => 20,
    "turns_used" => 0,
    "created_at" => "2026-01-01T00:00:00Z",
    "updated_at" => "2026-01-01T00:00:00Z",
    "completed_at" => nil,
    "error" => nil
  }

  @cluster_json %{
    "id" => "cl_1",
    "name" => "my-cluster",
    "model" => "llama3",
    "slug" => "my-cluster",
    "status" => "active",
    "host_ids" => ["host_abc"],
    "inference_url" => "https://api.miosa.ai/inference/my-cluster/v1",
    "created_at" => "2026-01-01T00:00:00Z",
    "updated_at" => "2026-01-01T00:00:00Z"
  }

  @secret_json %{
    "id" => "sec_1",
    "name" => "MY_TOKEN",
    "description" => nil,
    "host_id" => nil,
    "tenant_id" => "t_1",
    "created_at" => "2026-01-01T00:00:00Z",
    "updated_at" => "2026-01-01T00:00:00Z"
  }

  setup do
    bypass = Bypass.open()
    client = Miosa.client("msk_u_test", base_url: "http://localhost:#{bypass.port}/api/v1")
    {:ok, bypass: bypass, client: client}
  end

  # ── Hosts ──────────────────────────────────────────────────────────────────

  describe "Hosts.list/2" do
    test "GETs /opencomputers/hosts and returns list", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/opencomputers/hosts", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{
            "data" => [@host_json],
            "meta" => %{"total" => 1, "page" => 1, "per_page" => 20}
          })
        )
      end)

      assert {:ok, resp} = Hosts.list(client)
      assert [host] = resp["data"]
      assert host["id"] == "host_abc"
      assert host["status"] == "online"
    end

    test "returns error on 401", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/opencomputers/hosts", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          401,
          Jason.encode!(%{"error" => %{"code" => "UNAUTHORIZED", "message" => "Unauthorized"}})
        )
      end)

      assert {:error, %Error{status: 401}} = Hosts.list(client)
    end
  end

  describe "Hosts.create/2" do
    test "POSTs and returns host with host_key", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/opencomputers/hosts", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(Map.put(@host_json, "host_key", "hk_secret"))
        )
      end)

      assert {:ok, host} = Hosts.create(client, %{name: "my-mac"})
      assert host["host_key"] == "hk_secret"
      assert host["id"] == "host_abc"
    end
  end

  describe "Hosts.get/2" do
    test "GETs a single host", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/opencomputers/hosts/host_abc", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(@host_json))
      end)

      assert {:ok, host} = Hosts.get(client, "host_abc")
      assert host["name"] == "my-mac"
    end

    test "returns error on 404", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/opencomputers/hosts/bad", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          404,
          Jason.encode!(%{"error" => %{"code" => "NOT_FOUND", "message" => "Host not found"}})
        )
      end)

      assert {:error, %Error{status: 404}} = Hosts.get(client, "bad")
    end
  end

  describe "Hosts.revoke/2" do
    test "issues DELETE and returns :ok on 204", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "DELETE", "/api/v1/opencomputers/hosts/host_abc", fn conn ->
        Plug.Conn.send_resp(conn, 204, "")
      end)

      assert {:ok, _} = Hosts.revoke(client, "host_abc")
    end
  end

  # ── Jobs ───────────────────────────────────────────────────────────────────

  describe "Jobs.run/3" do
    test "POSTs to /exec and returns completed job", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/opencomputers/hosts/host_abc/exec", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(@job_json))
      end)

      assert {:ok, job} = Jobs.run(client, "host_abc", %{command: "npm test"})
      assert job["id"] == "job_1"
      assert job["exit_code"] == 0
      assert job["status"] == "completed"
    end
  end

  describe "Jobs.list/3" do
    test "GETs job list for a host", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/opencomputers/hosts/host_abc/exec", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{
            "data" => [@job_json],
            "meta" => %{"total" => 1, "page" => 1, "per_page" => 20}
          })
        )
      end)

      assert {:ok, resp} = Jobs.list(client, "host_abc")
      assert [job] = resp["data"]
      assert job["command"] == "npm test"
    end
  end

  describe "Jobs.cancel/3" do
    test "issues DELETE and returns ok on 204", %{bypass: bypass, client: client} do
      Bypass.expect_once(
        bypass,
        "DELETE",
        "/api/v1/opencomputers/hosts/host_abc/exec/job_1",
        fn conn ->
          Plug.Conn.send_resp(conn, 204, "")
        end
      )

      assert {:ok, _} = Jobs.cancel(client, "host_abc", "job_1")
    end
  end

  # ── Tunnels ────────────────────────────────────────────────────────────────

  describe "Tunnels.create/3" do
    test "POSTs and returns tunnel with public_url", %{bypass: bypass, client: client} do
      Bypass.expect_once(
        bypass,
        "POST",
        "/api/v1/opencomputers/hosts/host_abc/tunnels",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.send_resp(200, Jason.encode!(@tunnel_json))
        end
      )

      assert {:ok, tunnel} = Tunnels.create(client, "host_abc", %{target_port: 3000})
      assert tunnel["public_url"] == "https://api.miosa.ai/t/abc123"
      assert tunnel["target_port"] == 3000
    end
  end

  describe "Tunnels.delete/3" do
    test "issues DELETE and returns ok on 204", %{bypass: bypass, client: client} do
      Bypass.expect_once(
        bypass,
        "DELETE",
        "/api/v1/opencomputers/hosts/host_abc/tunnels/tun_1",
        fn conn ->
          Plug.Conn.send_resp(conn, 204, "")
        end
      )

      assert {:ok, _} = Tunnels.delete(client, "host_abc", "tun_1")
    end
  end

  # ── Agents ─────────────────────────────────────────────────────────────────

  describe "Agents.dispatch/3" do
    test "POSTs and returns the session", %{bypass: bypass, client: client} do
      Bypass.expect_once(
        bypass,
        "POST",
        "/api/v1/opencomputers/hosts/host_abc/agent/dispatch",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.send_resp(200, Jason.encode!(@session_json))
        end
      )

      assert {:ok, session} = Agents.dispatch(client, "host_abc", %{task: "run tests"})
      assert session["id"] == "sess_1"
      assert session["status"] == "pending"
    end
  end

  describe "Agents.cancel/3" do
    test "issues DELETE and returns ok on 204", %{bypass: bypass, client: client} do
      Bypass.expect_once(
        bypass,
        "DELETE",
        "/api/v1/opencomputers/hosts/host_abc/agent/sessions/sess_1",
        fn conn ->
          Plug.Conn.send_resp(conn, 204, "")
        end
      )

      assert {:ok, _} = Agents.cancel(client, "host_abc", "sess_1")
    end
  end

  # ── Clusters ───────────────────────────────────────────────────────────────

  describe "Clusters.list/1" do
    test "returns cluster list with inference_url", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/opencomputers/clusters", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"data" => [@cluster_json]}))
      end)

      assert {:ok, resp} = Clusters.list(client)
      assert [cluster] = resp["data"]
      assert cluster["id"] == "cl_1"
      assert cluster["inference_url"] == "https://api.miosa.ai/inference/my-cluster/v1"
    end
  end

  # ── Secrets ────────────────────────────────────────────────────────────────

  describe "Secrets.create/2" do
    test "POSTs and returns secret metadata", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/opencomputers/secrets", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(@secret_json))
      end)

      assert {:ok, secret} = Secrets.create(client, %{name: "MY_TOKEN", value: "s3cr3t"})
      assert secret["id"] == "sec_1"
      assert secret["name"] == "MY_TOKEN"
      refute Map.has_key?(secret, "value")
    end
  end

  describe "Secrets.delete/2" do
    test "issues DELETE and returns ok on 204", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "DELETE", "/api/v1/opencomputers/secrets/sec_1", fn conn ->
        Plug.Conn.send_resp(conn, 204, "")
      end)

      assert {:ok, _} = Secrets.delete(client, "sec_1")
    end
  end
end
