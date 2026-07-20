defmodule Miosa.Sandbox.FilesTest do
  use ExUnit.Case, async: true

  alias Miosa.Sandbox.Files

  setup do
    bypass = Bypass.open()
    client = Miosa.client("msk_u_test", base_url: "http://localhost:#{bypass.port}/api/v1")
    {:ok, bypass: bypass, client: client}
  end

  describe "tree/3" do
    test "returns tree on 200", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/sandboxes/sbx-1/files/tree", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{"data" => %{"path" => "/workspace", "type" => "dir", "children" => []}})
        )
      end)

      assert {:ok, tree} = Files.tree(client, "sbx-1")
      assert tree["path"] == "/workspace"
    end
  end

  describe "write_many/3" do
    test "encodes files and returns written list", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/sandboxes/sbx-1/files/write-many", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert length(decoded["files"]) == 1
        [f] = decoded["files"]
        assert f["path"] == "/workspace/hello.txt"
        assert Base.decode64!(f["content_base64"]) == "hello"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{
            "data" => %{
              "written" => [%{"path" => "/workspace/hello.txt", "size_bytes" => 5}],
              "failed" => []
            }
          })
        )
      end)

      assert {:ok, result} =
               Files.write_many(client, "sbx-1", [
                 %{path: "/workspace/hello.txt", content: "hello"}
               ])

      assert length(result["written"]) == 1
    end
  end
end
