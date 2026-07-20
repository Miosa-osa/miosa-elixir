defmodule Miosa.Sandbox.ShareTest do
  use ExUnit.Case, async: true

  alias Miosa.Sandbox.Share

  setup do
    bypass = Bypass.open()
    client = Miosa.client("msk_u_test", base_url: "http://localhost:#{bypass.port}/api/v1")
    {:ok, bypass: bypass, client: client}
  end

  describe "create/3" do
    test "creates a share URL", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/sandboxes/sbx-1/shares", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          201,
          Jason.encode!(%{
            "data" => %{
              "share_id" => "sh_1",
              "share_url" => "https://example.com?ms=tok",
              "scope" => "read"
            }
          })
        )
      end)

      assert {:ok, share} = Share.create(client, "sbx-1")
      assert share["share_id"] == "sh_1"
    end
  end

  describe "list/2" do
    test "lists shares", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/sandboxes/sbx-1/shares", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"data" => [%{"share_id" => "sh_1"}]}))
      end)

      assert {:ok, [s]} = Share.list(client, "sbx-1")
      assert s["share_id"] == "sh_1"
    end
  end

  describe "revoke/3" do
    test "revokes a share", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "DELETE", "/api/v1/sandboxes/sbx-1/shares/sh_1", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true}))
      end)

      assert {:ok, _} = Share.revoke(client, "sbx-1", "sh_1")
    end
  end
end
