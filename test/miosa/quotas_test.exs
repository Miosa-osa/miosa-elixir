defmodule Miosa.QuotasTest do
  use ExUnit.Case, async: true

  alias Miosa.Quotas

  setup do
    bypass = Bypass.open()
    client = Miosa.client("msk_u_test", base_url: "http://localhost:#{bypass.port}/api/v1")
    {:ok, bypass: bypass, client: client}
  end

  describe "get/2" do
    test "returns quota on 200", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/quotas/external/user-1", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"data" => %{"max_sandboxes" => 5}}))
      end)

      assert {:ok, quota} = Quotas.get(client, "user-1")
      assert quota["max_sandboxes"] == 5
    end
  end

  describe "set/3" do
    test "sends PUT with limits", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "PUT", "/api/v1/quotas/external/user-1", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded["max_sandboxes"] == 10

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"data" => %{"max_sandboxes" => 10}}))
      end)

      assert {:ok, _} = Quotas.set(client, "user-1", %{max_sandboxes: 10})
    end
  end

  describe "delete/2" do
    test "reverts to tenant default", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "DELETE", "/api/v1/quotas/external/user-1", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true}))
      end)

      assert :ok = Quotas.delete(client, "user-1")
    end
  end
end
