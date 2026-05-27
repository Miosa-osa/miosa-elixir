defmodule Miosa.Phase1CoverageTest do
  use ExUnit.Case, async: true

  alias Miosa.{Sandboxes, Tenant, Webhooks}

  setup do
    bypass = Bypass.open()
    client = Miosa.client("msk_u_test", base_url: "http://localhost:#{bypass.port}/api/v1")
    {:ok, bypass: bypass, client: client}
  end

  # ── Tenant.preview_domain ──────────────────────────────────────────────────

  describe "Tenant.get_preview_domain/1" do
    test "returns domain info on 200", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/tenant/preview-domain", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{"domain" => "preview.acme.com", "verified_at" => nil})
        )
      end)

      assert {:ok, body} = Tenant.get_preview_domain(client)
      assert body["domain"] == "preview.acme.com"
    end
  end

  describe "Tenant.set_preview_domain/2" do
    test "sends PUT with domain", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "PUT", "/api/v1/tenant/preview-domain", fn conn ->
        {:ok, raw, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(raw)
        assert decoded["domain"] == "preview.acme.com"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"domain" => "preview.acme.com"}))
      end)

      assert {:ok, _} = Tenant.set_preview_domain(client, "preview.acme.com")
    end
  end

  describe "Tenant.verify_preview_domain/1" do
    test "returns verification result", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/tenant/preview-domain/verify", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{"verified" => true, "target" => "proxy.miosa.app", "records" => []})
        )
      end)

      assert {:ok, result} = Tenant.verify_preview_domain(client)
      assert result["verified"] == true
    end
  end

  # ── Tenant.branding ────────────────────────────────────────────────────────

  describe "Tenant.set_branding/2" do
    test "sends PUT with branding keys", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "PUT", "/api/v1/tenant/branding", fn conn ->
        {:ok, raw, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(raw)
        assert decoded["product_name"] == "Acme AI"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"product_name" => "Acme AI"}))
      end)

      assert {:ok, _} = Tenant.set_branding(client, %{product_name: "Acme AI"})
    end
  end

  describe "Tenant.get_branding/1" do
    test "returns branding on 200", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/tenant/branding", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"product_name" => "Acme AI"}))
      end)

      assert {:ok, body} = Tenant.get_branding(client)
      assert body["product_name"] == "Acme AI"
    end
  end

  # ── Sandboxes.update ───────────────────────────────────────────────────────

  describe "Sandboxes.update/3" do
    test "sends PATCH /sandboxes/:id with allowed fields", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "PATCH", "/api/v1/sandboxes/sbx_123", fn conn ->
        {:ok, raw, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(raw)
        assert decoded["name"] == "renamed"
        assert decoded["slug"] == "my-slug"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"id" => "sbx_123", "name" => "renamed"}))
      end)

      assert {:ok, body} = Sandboxes.update(client, "sbx_123", %{name: "renamed", slug: "my-slug"})
      assert body["name"] == "renamed"
    end

    test "drops nil values from body", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "PATCH", "/api/v1/sandboxes/sbx_123", fn conn ->
        {:ok, raw, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(raw)
        refute Map.has_key?(decoded, "slug")

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"id" => "sbx_123"}))
      end)

      assert {:ok, _} = Sandboxes.update(client, "sbx_123", %{name: "x", slug: nil})
    end
  end

  # ── Sandboxes.preview_token ────────────────────────────────────────────────

  describe "Sandboxes.preview_token/3" do
    test "sends POST /sandboxes/:id/preview-token", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/sandboxes/sbx_123/preview-token", fn conn ->
        {:ok, raw, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(raw)
        assert decoded["expires_in"] == 3600
        assert decoded["scope"] == "read"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{
            "token" => "tok_xyz",
            "url" => "https://preview.miosa.app?t=tok_xyz",
            "expires_at" => "2026-05-26T01:00:00Z",
            "scope" => "read"
          })
        )
      end)

      assert {:ok, result} = Sandboxes.preview_token(client, "sbx_123")
      assert result["token"] == "tok_xyz"
    end
  end

  # ── Webhooks.verify_signature ─────────────────────────────────────────────

  describe "Webhooks.verify_signature/3" do
    defp make_header(payload, secret, ts \\ nil) do
      t = ts || System.os_time(:second)
      signed = "#{t}." <> payload
      sig = :crypto.mac(:hmac, :sha256, secret, signed) |> Base.encode16(case: :lower)
      "t=#{t},v1=#{sig}"
    end

    test "returns {:ok, true} for valid signature" do
      payload = ~s({"event":"sandbox.created"})
      header = make_header(payload, "secret123")
      assert {:ok, true} = Webhooks.verify_signature(payload, header, "secret123")
    end

    test "returns {:error, :invalid_signature} for wrong secret" do
      payload = ~s({"event":"sandbox.created"})
      header = make_header(payload, "secret123")
      assert {:error, :invalid_signature} = Webhooks.verify_signature(payload, header, "wrongsecret")
    end

    test "returns {:error, :timestamp_too_old} for stale timestamp" do
      payload = "body"
      old_ts = System.os_time(:second) - 400
      header = make_header(payload, "secret123", old_ts)
      assert {:error, :timestamp_too_old} = Webhooks.verify_signature(payload, header, "secret123")
    end

    test "returns {:error, :malformed_header} for unparseable header" do
      assert {:error, :malformed_header} = Webhooks.verify_signature("body", "malformed", "secret")
    end
  end
end
