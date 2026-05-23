defmodule Miosa.SecretsTest do
  use ExUnit.Case, async: true

  alias Miosa.{Error, Secrets}

  setup do
    bypass = Bypass.open()
    client = Miosa.client("msk_u_test", base_url: "http://localhost:#{bypass.port}/api/v1")
    {:ok, bypass: bypass, client: client}
  end

  # ---------------------------------------------------------------------------
  # set/2
  # ---------------------------------------------------------------------------

  describe "set/2" do
    test "POST /egress/secrets returns the created secret", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/egress/secrets", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded["name"] == "MY_KEY"
        assert decoded["value"] == "secret-val"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(201, Jason.encode!(%{"id" => "sec_1", "name" => "MY_KEY"}))
      end)

      assert {:ok, %{"id" => "sec_1", "name" => "MY_KEY"}} =
               Secrets.set(client, %{name: "MY_KEY", value: "secret-val"})
    end

    test "unwraps data envelope", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/egress/secrets", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          201,
          Jason.encode!(%{"data" => %{"id" => "sec_2", "name" => "X"}})
        )
      end)

      assert {:ok, %{"id" => "sec_2"}} = Secrets.set(client, %{name: "X", value: "v"})
    end

    test "returns error on 422", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/egress/secrets", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(422, Jason.encode!(%{"error" => "Name taken"}))
      end)

      assert {:error, %Error{status: 422}} = Secrets.set(client, %{name: "dup", value: "v"})
    end
  end

  # ---------------------------------------------------------------------------
  # list/2
  # ---------------------------------------------------------------------------

  describe "list/2" do
    test "GET /egress/secrets returns a list", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/egress/secrets", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!([%{"id" => "s1"}, %{"id" => "s2"}])
        )
      end)

      assert {:ok, [%{"id" => "s1"}, %{"id" => "s2"}]} = Secrets.list(client)
    end

    test "forwards filters as query params", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/egress/secrets", fn conn ->
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.query_params["resource_id"] == "sb_99"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!([]))
      end)

      assert {:ok, []} = Secrets.list(client, %{resource_id: "sb_99"})
    end

    test "unwraps secrets envelope", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/egress/secrets", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{"secrets" => [%{"id" => "s3"}]})
        )
      end)

      assert {:ok, [%{"id" => "s3"}]} = Secrets.list(client)
    end
  end

  # ---------------------------------------------------------------------------
  # get/2
  # ---------------------------------------------------------------------------

  describe "get/2" do
    test "GET /egress/secrets/:id returns the secret", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/egress/secrets/sec_99", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"id" => "sec_99", "name" => "K"}))
      end)

      assert {:ok, %{"id" => "sec_99"}} = Secrets.get(client, "sec_99")
    end

    test "returns 404 error for missing secret", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/egress/secrets/missing", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          404,
          Jason.encode!(%{"error" => "Not found", "code" => "NOT_FOUND"})
        )
      end)

      assert {:error, %Error{status: 404, code: "NOT_FOUND"}} = Secrets.get(client, "missing")
    end
  end

  # ---------------------------------------------------------------------------
  # rotate/3
  # ---------------------------------------------------------------------------

  describe "rotate/3" do
    test "PATCH /egress/secrets/:id with new value", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "PATCH", "/api/v1/egress/secrets/sec_1", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded["value"] == "new-value"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"id" => "sec_1", "name" => "K"}))
      end)

      assert {:ok, %{"id" => "sec_1"}} = Secrets.rotate(client, "sec_1", %{value: "new-value"})
    end
  end

  # ---------------------------------------------------------------------------
  # delete/2
  # ---------------------------------------------------------------------------

  describe "delete/2" do
    test "DELETE /egress/secrets/:id returns :ok on success", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "DELETE", "/api/v1/egress/secrets/sec_del", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true}))
      end)

      assert :ok = Secrets.delete(client, "sec_del")
    end
  end

  # ---------------------------------------------------------------------------
  # connect/3
  # ---------------------------------------------------------------------------

  describe "connect/3" do
    test "POST /egress/oauth/start returns an OauthFlow struct", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/egress/oauth/start", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded["provider"] == "github"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{
            "authorize_url" => "https://github.com/login/oauth/authorize?state=abc",
            "state" => "abc123"
          })
        )
      end)

      assert {:ok, flow} = Secrets.connect(client, "github")
      assert flow.authorize_url =~ "github.com"
      assert flow.state == "abc123"
      assert flow.provider == "github"
      assert %Miosa.OauthFlow{} = flow
    end
  end

  # ---------------------------------------------------------------------------
  # Bindings
  # ---------------------------------------------------------------------------

  describe "create_binding/2" do
    test "POST /egress/bindings with required attrs", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/egress/bindings", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded["secret_id"] == "sec_1"
        assert decoded["resource_id"] == "sb_1"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(201, Jason.encode!(%{"id" => "bind_1"}))
      end)

      assert {:ok, %{"id" => "bind_1"}} =
               Secrets.create_binding(client, %{
                 secret_id: "sec_1",
                 resource_id: "sb_1",
                 resource_type: "sandbox",
                 expose_as_env: "MY_VAR"
               })
    end
  end
end
