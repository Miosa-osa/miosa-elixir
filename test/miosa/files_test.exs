defmodule Miosa.FilesTest do
  use ExUnit.Case, async: true
  alias Miosa.Files

  setup do
    bypass = Bypass.open()
    client = Miosa.client("msk_u_test", base_url: "http://localhost:#{bypass.port}/api/v1")
    {:ok, bypass: bypass, client: client, cid: "comp_abc"}
  end

  describe "list/3" do
    test "returns list of FileEntry structs", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "GET", "/api/v1/computers/comp_abc/files/list", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!([
            %{
              "name" => "file.txt",
              "path" => "/home/user/file.txt",
              "type" => "file",
              "size" => 512
            },
            %{"name" => "docs", "path" => "/home/user/docs", "type" => "directory"}
          ])
        )
      end)

      assert {:ok, entries} = Files.list(client, cid, "/home/user")
      assert length(entries) == 2
      assert Enum.at(entries, 0).name == "file.txt"
      assert Enum.at(entries, 0).type == :file
      assert Enum.at(entries, 1).type == :directory
    end

    test "uses default path /home/user", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "GET", "/api/v1/computers/comp_abc/files/list", fn conn ->
        query = URI.decode_query(conn.query_string)
        assert query["path"] == "/home/user"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!([]))
      end)

      assert {:ok, []} = Files.list(client, cid)
    end
  end

  describe "download/3" do
    test "returns binary file content", %{bypass: bypass, client: client, cid: cid} do
      content = "hello, world!"

      Bypass.expect_once(bypass, "GET", "/api/v1/computers/comp_abc/files/download", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/octet-stream")
        |> Plug.Conn.send_resp(200, content)
      end)

      assert {:ok, ^content} = Files.download(client, cid, "/home/user/file.txt")
    end
  end

  describe "download_to/4" do
    test "writes content to local path", %{bypass: bypass, client: client, cid: cid} do
      content = "binary content"
      local_path = Path.join(System.tmp_dir!(), "miosa_test_#{System.unique_integer()}.txt")

      Bypass.expect_once(bypass, "GET", "/api/v1/computers/comp_abc/files/download", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/octet-stream")
        |> Plug.Conn.send_resp(200, content)
      end)

      assert :ok = Files.download_to(client, cid, "/home/user/file.txt", local_path)
      assert File.read!(local_path) == content
      File.rm!(local_path)
    end
  end

  describe "export/3" do
    test "returns ExportResult with url", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "POST", "/api/v1/computers/comp_abc/files/export", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{
            "url" => "https://storage.miosa.ai/files/abc123?sig=xyz",
            "expires_at" => "2026-04-11T01:00:00Z"
          })
        )
      end)

      assert {:ok, export} = Files.export(client, cid, "/home/user/report.pdf")
      assert export.url == "https://storage.miosa.ai/files/abc123?sig=xyz"
      assert export.expires_at == "2026-04-11T01:00:00Z"
    end
  end

  describe "delete/4" do
    test "returns :ok on success", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "DELETE", "/api/v1/computers/comp_abc/files", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true}))
      end)

      assert :ok = Files.delete(client, cid, "/home/user/old.txt")
    end
  end

  describe "write/4" do
    test "uploads in-memory content as multipart", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "POST", "/api/v1/computers/comp_abc/files/upload", fn conn ->
        # Verify it's a multipart request
        content_type = Plug.Conn.get_req_header(conn, "content-type") |> List.first()
        assert String.starts_with?(content_type, "multipart/form-data")

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true}))
      end)

      assert :ok = Files.write(client, cid, "/home/user/hello.txt", "Hello!")
    end
  end
end
