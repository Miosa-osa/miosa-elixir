defmodule Miosa.CustomDomainsTest do
  use ExUnit.Case, async: true

  alias Miosa.{CustomDomains, Error}

  setup do
    bypass = Bypass.open()
    client = Miosa.client("msk_u_test", base_url: "http://localhost:#{bypass.port}/api/v1")
    {:ok, bypass: bypass, client: client, cid: "comp_abc"}
  end

  describe "register/3" do
    test "returns a CustomDomain struct on 201", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "POST", "/api/v1/computers/comp_abc/domains", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded["domain"] == "app.example.com"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          201,
          Jason.encode!(%{
            "id" => "dom_xyz",
            "computer_id" => cid,
            "domain" => "app.example.com",
            "port" => 3000,
            "tls" => true,
            "status" => "pending",
            "dns_instructions" => %{"type" => "CNAME", "value" => "proxy.miosa.ai"}
          })
        )
      end)

      assert {:ok, domain} =
               CustomDomains.register(client, cid, %{domain: "app.example.com", port: 3000})

      assert domain.id == "dom_xyz"
      assert domain.domain == "app.example.com"
      assert domain.status == :pending
      assert domain.dns_instructions["type"] == "CNAME"
    end

    test "returns error when domain already registered", %{
      bypass: bypass,
      client: client,
      cid: cid
    } do
      Bypass.expect_once(bypass, "POST", "/api/v1/computers/comp_abc/domains", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          409,
          Jason.encode!(%{"error" => "Domain already registered", "code" => "CONFLICT"})
        )
      end)

      assert {:error, %Error{status: 409}} =
               CustomDomains.register(client, cid, %{domain: "app.example.com"})
    end
  end

  describe "list/2" do
    test "returns list of CustomDomain structs", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "GET", "/api/v1/computers/comp_abc/domains", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!([
            %{"id" => "d1", "domain" => "api.example.com", "status" => "active"},
            %{"id" => "d2", "domain" => "app.example.com", "status" => "pending"}
          ])
        )
      end)

      assert {:ok, domains} = CustomDomains.list(client, cid)
      assert length(domains) == 2
      assert Enum.at(domains, 0).status == :active
      assert Enum.at(domains, 1).status == :pending
    end

    test "returns empty list when no domains", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "GET", "/api/v1/computers/comp_abc/domains", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!([]))
      end)

      assert {:ok, []} = CustomDomains.list(client, cid)
    end
  end

  describe "verify/3" do
    test "returns updated domain with active status on success", %{
      bypass: bypass,
      client: client,
      cid: cid
    } do
      Bypass.expect_once(
        bypass,
        "POST",
        "/api/v1/computers/comp_abc/domains/dom_xyz/verify",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.send_resp(
            200,
            Jason.encode!(%{
              "id" => "dom_xyz",
              "domain" => "app.example.com",
              "status" => "active"
            })
          )
        end
      )

      assert {:ok, domain} = CustomDomains.verify(client, cid, "dom_xyz")
      assert domain.status == :active
    end

    test "returns error when DNS not configured", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(
        bypass,
        "POST",
        "/api/v1/computers/comp_abc/domains/dom_xyz/verify",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.send_resp(
            422,
            Jason.encode!(%{"error" => "DNS record not found", "code" => "DNS_NOT_FOUND"})
          )
        end
      )

      assert {:error, %Error{status: 422, code: "DNS_NOT_FOUND"}} =
               CustomDomains.verify(client, cid, "dom_xyz")
    end
  end

  describe "delete/3" do
    test "returns :ok on success", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(
        bypass,
        "DELETE",
        "/api/v1/computers/comp_abc/domains/dom_del",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true}))
        end
      )

      assert :ok = CustomDomains.delete(client, cid, "dom_del")
    end
  end
end
