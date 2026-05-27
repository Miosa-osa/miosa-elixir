defmodule Miosa.Sandbox.EnvTest do
  use ExUnit.Case, async: true

  alias Miosa.Sandbox.Env

  setup do
    bypass = Bypass.open()
    client = Miosa.client("msk_u_test", base_url: "http://localhost:#{bypass.port}/api/v1")
    {:ok, bypass: bypass, client: client}
  end

  describe "list/2" do
    test "returns env vars on 200", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/sandboxes/sbx-1/env", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"data" => [%{"key" => "FOO", "encrypted" => false}]}))
      end)

      assert {:ok, [var]} = Env.list(client, "sbx-1")
      assert var["key"] == "FOO"
    end
  end

  describe "set/3" do
    test "sends PUT and returns data", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "PUT", "/api/v1/sandboxes/sbx-1/env", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert [%{"key" => "BAR", "value" => "baz"}] = decoded["vars"]

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"data" => %{"ok" => true}}))
      end)

      assert {:ok, _} = Env.set(client, "sbx-1", [%{"key" => "BAR", "value" => "baz"}])
    end
  end

  describe "delete/3" do
    test "sends DELETE and returns response", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "DELETE", "/api/v1/sandboxes/sbx-1/env/FOO", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true}))
      end)

      assert {:ok, _} = Env.delete(client, "sbx-1", "FOO")
    end
  end
end
