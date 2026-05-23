defmodule Miosa.NetworkPolicyTest do
  use ExUnit.Case, async: true

  alias Miosa.{NetworkPolicy, Error}

  setup do
    bypass = Bypass.open()
    client = Miosa.client("msk_u_test", base_url: "http://localhost:#{bypass.port}/api/v1")
    {:ok, bypass: bypass, client: client, cid: "comp_abc"}
  end

  describe "get/2" do
    test "returns a NetworkPolicy struct", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "GET", "/api/v1/computers/comp_abc/network-policy", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{
            "computer_id" => cid,
            "rules" => [
              %{"direction" => "egress", "action" => "allow", "host" => "*", "port" => "*"}
            ],
            "updated_at" => "2026-01-01T00:00:00Z"
          })
        )
      end)

      assert {:ok, policy} = NetworkPolicy.get(client, cid)
      assert policy.computer_id == cid
      assert length(policy.rules) == 1
      [rule] = policy.rules
      assert rule.direction == :egress
      assert rule.action == :allow
    end

    test "returns error on 404", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "GET", "/api/v1/computers/comp_abc/network-policy", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          404,
          Jason.encode!(%{"error" => "Not found", "code" => "NOT_FOUND"})
        )
      end)

      assert {:error, %Error{status: 404}} = NetworkPolicy.get(client, cid)
    end
  end

  describe "set/3" do
    test "returns updated NetworkPolicy struct", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "PUT", "/api/v1/computers/comp_abc/network-policy", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert is_list(decoded["rules"])

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{
            "computer_id" => cid,
            "rules" => decoded["rules"],
            "updated_at" => "2026-01-01T12:00:00Z"
          })
        )
      end)

      params = %{
        rules: [
          %{direction: "egress", action: "allow", host: "api.example.com", port: 443},
          %{direction: "egress", action: "deny", host: "*", port: "*"}
        ]
      }

      assert {:ok, policy} = NetworkPolicy.set(client, cid, params)
      assert policy.computer_id == cid
      assert length(policy.rules) == 2
    end
  end

  describe "reset/2" do
    test "returns :ok on success", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(
        bypass,
        "DELETE",
        "/api/v1/computers/comp_abc/network-policy",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true}))
        end
      )

      assert :ok = NetworkPolicy.reset(client, cid)
    end
  end
end
