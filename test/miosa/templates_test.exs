defmodule Miosa.TemplatesTest do
  use ExUnit.Case, async: true

  alias Miosa.Templates

  setup do
    bypass = Bypass.open()
    client = Miosa.client("msk_u_test", base_url: "http://localhost:#{bypass.port}/api/v1")
    {:ok, bypass: bypass, client: client}
  end

  describe "list/1" do
    test "returns templates on 200", %{bypass: bypass, client: client} do
      templates = [
        %{"id" => "tpl-1", "name" => "miosa-sandbox", "description" => "Lightweight sandbox", "categories" => ["code"]}
      ]

      Bypass.expect_once(bypass, "GET", "/api/v1/sandbox-templates", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"data" => templates}))
      end)

      assert {:ok, [tpl]} = Templates.list(client)
      assert tpl["id"] == "tpl-1"
    end
  end
end
