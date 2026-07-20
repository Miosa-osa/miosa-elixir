defmodule Miosa.ComputersTest do
  use ExUnit.Case, async: true

  alias Miosa.{Computers, Error}

  # We test the response parsing logic using Bypass to mock the HTTP layer.
  # Integration tests against the live API are tagged :integration and skipped by default.

  setup do
    bypass = Bypass.open()
    client = Miosa.client("msk_u_test", base_url: "http://localhost:#{bypass.port}/api/v1")
    {:ok, bypass: bypass, client: client}
  end

  describe "create/2" do
    test "returns a Computer struct on 201", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/computers", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          201,
          Jason.encode!(%{
            "id" => "comp_123",
            "name" => "my-agent",
            "status" => "creating",
            "template_type" => "miosa-desktop",
            "size" => "small"
          })
        )
      end)

      assert {:ok, computer} = Computers.create(client, %{name: "my-agent"})
      assert computer.id == "comp_123"
      assert computer.name == "my-agent"
      assert computer.status == :creating
    end

    test "returns error on 402 insufficient credits", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/computers", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          402,
          Jason.encode!(%{
            "error" => "Insufficient credits",
            "code" => "INSUFFICIENT_CREDITS"
          })
        )
      end)

      assert {:error, %Error{status: 402, code: "INSUFFICIENT_CREDITS"}} =
               Computers.create(client, %{})
    end

    test "returns error on 401 unauthorized", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/computers", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(401, Jason.encode!(%{"error" => "Unauthorized"}))
      end)

      assert {:error, %Error{status: 401}} = Computers.create(client, %{})
    end
  end

  describe "list/1" do
    test "returns a list of Computer structs", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/computers", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!([
            %{"id" => "comp_1", "name" => "first", "status" => "running"},
            %{"id" => "comp_2", "name" => "second", "status" => "stopped"}
          ])
        )
      end)

      assert {:ok, computers} = Computers.list(client)
      assert length(computers) == 2
      assert Enum.at(computers, 0).id == "comp_1"
      assert Enum.at(computers, 0).status == :running
      assert Enum.at(computers, 1).status == :stopped
    end

    test "returns empty list when no computers", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/computers", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!([]))
      end)

      assert {:ok, []} = Computers.list(client)
    end

    test "handles data-wrapped response", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/computers", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{
            "data" => [%{"id" => "c1", "name" => "n1", "status" => "running"}]
          })
        )
      end)

      assert {:ok, [computer]} = Computers.list(client)
      assert computer.id == "c1"
    end
  end

  describe "get/2" do
    test "fetches a single computer", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/computers/comp_abc", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{
            "id" => "comp_abc",
            "name" => "workspace",
            "status" => "running"
          })
        )
      end)

      assert {:ok, computer} = Computers.get(client, "comp_abc")
      assert computer.id == "comp_abc"
    end

    test "returns 404 error for missing computer", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/computers/nonexistent", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          404,
          Jason.encode!(%{"error" => "Not found", "code" => "NOT_FOUND"})
        )
      end)

      assert {:error, %Error{status: 404, code: "NOT_FOUND"}} =
               Computers.get(client, "nonexistent")
    end
  end

  describe "viewer password" do
    test "fetches external viewer password status", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/computers/comp_view/viewer-password", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{
            "viewer_password_set" => true,
            "viewer_password_set_at" => "2026-06-24T00:00:00Z"
          })
        )
      end)

      assert {:ok, status} = Computers.viewer_password(client, "comp_view")
      assert status["viewer_password_set"] == true
      assert status["viewer_password_set_at"] == "2026-06-24T00:00:00Z"
    end

    test "rotates and returns external viewer password once", %{bypass: bypass, client: client} do
      Bypass.expect_once(
        bypass,
        "POST",
        "/api/v1/computers/comp_view/viewer-password/rotate",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.send_resp(
            200,
            Jason.encode!(%{
              "viewer_password" => "xxxx-yyyy-zzzz-wwww",
              "viewer_password_set_at" => "2026-06-24T00:00:00Z"
            })
          )
        end
      )

      assert {:ok, rotation} = Computers.rotate_viewer_password(client, "comp_view")
      assert rotation["viewer_password"] == "xxxx-yyyy-zzzz-wwww"
    end
  end

  describe "delete/2" do
    test "returns :ok on success", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "DELETE", "/api/v1/computers/comp_xyz", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true}))
      end)

      assert :ok = Computers.delete(client, "comp_xyz")
    end
  end
end
