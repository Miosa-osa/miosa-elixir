defmodule Miosa.WorkspacesTest do
  use ExUnit.Case, async: true

  alias Miosa.{Workspaces, Error}

  setup do
    bypass = Bypass.open()
    client = Miosa.client("msk_u_test", base_url: "http://localhost:#{bypass.port}/api/v1")
    {:ok, bypass: bypass, client: client}
  end

  describe "create/2" do
    test "returns a Workspace struct on 201", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/workspaces", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          201,
          Jason.encode!(%{
            "id" => "ws_abc",
            "name" => "my-project",
            "metadata" => %{},
            "created_at" => "2026-01-01T00:00:00Z"
          })
        )
      end)

      assert {:ok, ws} = Workspaces.create(client, %{name: "my-project"})
      assert ws.id == "ws_abc"
      assert ws.name == "my-project"
    end

    test "returns error on 422", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/workspaces", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(422, Jason.encode!(%{"error" => "Name is required"}))
      end)

      assert {:error, %Error{status: 422}} = Workspaces.create(client, %{})
    end
  end

  describe "list/1" do
    test "returns a list of Workspace structs", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/workspaces", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!([
            %{"id" => "ws_1", "name" => "alpha"},
            %{"id" => "ws_2", "name" => "beta"}
          ])
        )
      end)

      assert {:ok, workspaces} = Workspaces.list(client)
      assert length(workspaces) == 2
      assert Enum.at(workspaces, 0).id == "ws_1"
    end

    test "handles data-wrapped response", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/workspaces", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{"data" => [%{"id" => "ws_3", "name" => "gamma"}]})
        )
      end)

      assert {:ok, [ws]} = Workspaces.list(client)
      assert ws.id == "ws_3"
    end

    test "returns empty list when none exist", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/workspaces", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!([]))
      end)

      assert {:ok, []} = Workspaces.list(client)
    end
  end

  describe "get/2" do
    test "fetches a workspace by id", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/workspaces/ws_abc", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"id" => "ws_abc", "name" => "project"}))
      end)

      assert {:ok, ws} = Workspaces.get(client, "ws_abc")
      assert ws.id == "ws_abc"
    end

    test "returns 404 for unknown workspace", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/workspaces/nope", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          404,
          Jason.encode!(%{"error" => "Not found", "code" => "NOT_FOUND"})
        )
      end)

      assert {:error, %Error{status: 404, code: "NOT_FOUND"}} = Workspaces.get(client, "nope")
    end
  end

  describe "update/3" do
    test "returns updated Workspace struct", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "PATCH", "/api/v1/workspaces/ws_abc", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"id" => "ws_abc", "name" => "renamed"}))
      end)

      assert {:ok, ws} = Workspaces.update(client, "ws_abc", %{name: "renamed"})
      assert ws.name == "renamed"
    end
  end

  describe "delete/2" do
    test "returns :ok on success", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "DELETE", "/api/v1/workspaces/ws_del", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true}))
      end)

      assert :ok = Workspaces.delete(client, "ws_del")
    end
  end

  describe "list_computers/2" do
    test "returns list of computers for workspace", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/workspaces/ws_abc/computers", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!([
            %{"id" => "comp_1", "name" => "machine-1", "status" => "running"}
          ])
        )
      end)

      assert {:ok, [computer]} = Workspaces.list_computers(client, "ws_abc")
      assert computer.id == "comp_1"
      assert computer.status == :running
    end
  end
end
