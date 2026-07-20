defmodule Miosa.TemplatesTest do
  use ExUnit.Case, async: true

  alias Miosa.Templates

  setup do
    bypass = Bypass.open()
    client = Miosa.client("msk_u_test", base_url: "http://localhost:#{bypass.port}/api/v1")
    {:ok, bypass: bypass, client: client}
  end

  describe "catalog/1" do
    test "returns the product template catalog", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/templates", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(catalog_body()))
      end)

      assert {:ok, %{"templates" => templates}} = Templates.catalog(client)
      assert length(templates) == 2
    end
  end

  describe "list/2" do
    test "lists canonical product templates and filters by product", %{
      bypass: bypass,
      client: client
    } do
      Bypass.expect_once(bypass, "GET", "/api/v1/templates", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(catalog_body()))
      end)

      assert {:ok, [%{"id" => "miosa-desktop"}]} =
               Templates.list(client, product: "computer")
    end
  end

  describe "get/2 and readiness/2" do
    test "gets one product template and returns size readiness", %{
      bypass: bypass,
      client: client
    } do
      Bypass.expect(bypass, "GET", "/api/v1/templates", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(catalog_body()))
      end)

      assert {:ok, %{"id" => "miosa-sandbox"}} = Templates.get(client, "miosa-sandbox")

      assert {:ok, [%{"size" => "small", "state" => "fast_ready"}]} =
               Templates.readiness(client, "miosa-sandbox")
    end
  end

  defp catalog_body do
    %{
      "templates" => [
        %{
          "id" => "miosa-sandbox",
          "product" => "sandbox",
          "default_size" => "small",
          "sizes" => [%{"size" => "small", "state" => "fast_ready"}]
        },
        %{
          "id" => "miosa-desktop",
          "product" => "computer",
          "default_size" => "small",
          "sizes" => [%{"size" => "small", "state" => "fast_ready"}]
        }
      ]
    }
  end
end
