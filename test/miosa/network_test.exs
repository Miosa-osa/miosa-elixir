defmodule Miosa.NetworkTest do
  use ExUnit.Case, async: true

  alias Miosa.{Error, Network}

  setup do
    bypass = Bypass.open()
    client = Miosa.client("msk_u_test", base_url: "http://localhost:#{bypass.port}/api/v1")
    {:ok, bypass: bypass, client: client}
  end

  # ---------------------------------------------------------------------------
  # allow/3
  # ---------------------------------------------------------------------------

  describe "allow/3" do
    test "POST /egress/allowlist with effect=allow", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/egress/allowlist", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded["host"] == "api.github.com"
        assert decoded["effect"] == "allow"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          201,
          Jason.encode!(%{"id" => "rule_1", "host" => "api.github.com"})
        )
      end)

      assert {:ok, %{"id" => "rule_1"}} = Network.allow(client, "api.github.com")
    end

    test "forwards optional opts", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/egress/allowlist", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded["note"] == "CI pipeline"
        assert decoded["methods"] == ["GET", "POST"]

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(201, Jason.encode!(%{"id" => "rule_2"}))
      end)

      assert {:ok, _} =
               Network.allow(client, "api.example.com",
                 note: "CI pipeline",
                 methods: ["GET", "POST"]
               )
    end
  end

  # ---------------------------------------------------------------------------
  # deny/3
  # ---------------------------------------------------------------------------

  describe "deny/3" do
    test "POST /egress/allowlist with effect=deny", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/egress/allowlist", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded["effect"] == "deny"
        assert decoded["host"] == "bad.actor.io"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(201, Jason.encode!(%{"id" => "rule_deny"}))
      end)

      assert {:ok, %{"id" => "rule_deny"}} = Network.deny(client, "bad.actor.io")
    end
  end

  # ---------------------------------------------------------------------------
  # rules/3
  # ---------------------------------------------------------------------------

  describe "rules/3" do
    test "GET /egress/allowlist returns a list of rules", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/egress/allowlist", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!([%{"id" => "r1"}, %{"id" => "r2"}])
        )
      end)

      assert {:ok, [%{"id" => "r1"}, %{"id" => "r2"}]} = Network.rules(client)
    end

    test "accepts policy_id filter", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/egress/allowlist", fn conn ->
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.query_params["policy_id"] == "pol_99"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!([]))
      end)

      assert {:ok, []} = Network.rules(client, "pol_99")
    end
  end

  # ---------------------------------------------------------------------------
  # policies/2
  # ---------------------------------------------------------------------------

  describe "policies/2" do
    test "GET /egress/policies returns a list", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/egress/policies", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{"policies" => [%{"id" => "p1", "mode" => "enforce"}]})
        )
      end)

      assert {:ok, [%{"id" => "p1"}]} = Network.policies(client)
    end
  end

  # ---------------------------------------------------------------------------
  # lockdown/2 + observe/2
  # ---------------------------------------------------------------------------

  describe "lockdown/2" do
    test "PATCH /egress/policies with mode=enforce", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "PATCH", "/api/v1/egress/policies", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded["mode"] == "enforce"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"mode" => "enforce"}))
      end)

      assert {:ok, %{"mode" => "enforce"}} = Network.lockdown(client)
    end
  end

  describe "observe/2" do
    test "PATCH /egress/policies with mode=audit_only", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "PATCH", "/api/v1/egress/policies", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded["mode"] == "audit_only"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"mode" => "audit_only"}))
      end)

      assert {:ok, %{"mode" => "audit_only"}} = Network.observe(client)
    end

    test "PATCH /egress/policies/:id when policy_id provided", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "PATCH", "/api/v1/egress/policies/pol_1", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded["mode"] == "audit_only"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"id" => "pol_1", "mode" => "audit_only"}))
      end)

      assert {:ok, %{"mode" => "audit_only"}} = Network.observe(client, policy_id: "pol_1")
    end
  end

  # ---------------------------------------------------------------------------
  # suggestions/2
  # ---------------------------------------------------------------------------

  describe "suggestions/2" do
    test "GET /egress/audit/suggestions returns a list", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/egress/audit/suggestions", fn conn ->
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.query_params["since"] == "7d"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!([%{"host" => "api.openai.com", "score" => 0.9}])
        )
      end)

      assert {:ok, [%{"host" => "api.openai.com"}]} = Network.suggestions(client)
    end

    test "returns error on unexpected status", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/egress/audit/suggestions", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(500, Jason.encode!(%{"error" => "Internal error"}))
      end)

      assert {:error, %Error{status: 500}} = Network.suggestions(client)
    end
  end
end
