defmodule Miosa.ServicesTest do
  use ExUnit.Case, async: true

  alias Miosa.{Services, Error}

  setup do
    bypass = Bypass.open()
    client = Miosa.client("msk_u_test", base_url: "http://localhost:#{bypass.port}/api/v1")
    {:ok, bypass: bypass, client: client, cid: "comp_abc"}
  end

  describe "create/3" do
    test "returns a Service struct on 201", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "POST", "/api/v1/computers/comp_abc/services", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded["name"] == "web"
        assert decoded["command"] == "python -m http.server 8080"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          201,
          Jason.encode!(%{
            "id" => "svc_123",
            "computer_id" => cid,
            "name" => "web",
            "command" => "python -m http.server 8080",
            "status" => "stopped"
          })
        )
      end)

      assert {:ok, svc} =
               Services.create(client, cid, %{name: "web", command: "python -m http.server 8080"})

      assert svc.id == "svc_123"
      assert svc.name == "web"
      assert svc.status == :stopped
    end

    test "returns error on validation failure", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "POST", "/api/v1/computers/comp_abc/services", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(422, Jason.encode!(%{"error" => "command is required"}))
      end)

      assert {:error, %Error{status: 422}} = Services.create(client, cid, %{name: "web"})
    end
  end

  describe "list/2" do
    test "returns list of Service structs", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "GET", "/api/v1/computers/comp_abc/services", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!([
            %{"id" => "s1", "computer_id" => cid, "name" => "web", "status" => "running"},
            %{"id" => "s2", "computer_id" => cid, "name" => "db", "status" => "stopped"}
          ])
        )
      end)

      assert {:ok, services} = Services.list(client, cid)
      assert length(services) == 2
      assert Enum.at(services, 0).status == :running
      assert Enum.at(services, 1).status == :stopped
    end
  end

  describe "get/3" do
    test "fetches a service by id", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "GET", "/api/v1/computers/comp_abc/services/svc_123", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{
            "id" => "svc_123",
            "computer_id" => cid,
            "name" => "web",
            "status" => "running"
          })
        )
      end)

      assert {:ok, svc} = Services.get(client, cid, "svc_123")
      assert svc.id == "svc_123"
      assert svc.status == :running
    end
  end

  describe "start/3" do
    test "returns :ok on success", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(
        bypass,
        "POST",
        "/api/v1/computers/comp_abc/services/svc_1/start",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true}))
        end
      )

      assert :ok = Services.start(client, cid, "svc_1")
    end
  end

  describe "stop/3" do
    test "returns :ok on success", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(
        bypass,
        "POST",
        "/api/v1/computers/comp_abc/services/svc_1/stop",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true}))
        end
      )

      assert :ok = Services.stop(client, cid, "svc_1")
    end
  end

  describe "restart/3" do
    test "returns :ok on success", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(
        bypass,
        "POST",
        "/api/v1/computers/comp_abc/services/svc_1/restart",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true}))
        end
      )

      assert :ok = Services.restart(client, cid, "svc_1")
    end
  end

  describe "delete/3" do
    test "returns :ok on success", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(
        bypass,
        "DELETE",
        "/api/v1/computers/comp_abc/services/svc_del",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true}))
        end
      )

      assert :ok = Services.delete(client, cid, "svc_del")
    end
  end
end
