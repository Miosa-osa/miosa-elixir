defmodule Miosa.OauthFlowTest do
  use ExUnit.Case, async: true

  alias Miosa.{OauthFlow, Secrets}

  setup do
    bypass = Bypass.open()
    client = Miosa.client("msk_u_test", base_url: "http://localhost:#{bypass.port}/api/v1")
    {:ok, bypass: bypass, client: client}
  end

  # ---------------------------------------------------------------------------
  # struct fields
  # ---------------------------------------------------------------------------

  describe "OauthFlow struct" do
    test "has expected fields" do
      client = Miosa.client("msk_u_dummy")

      flow = %OauthFlow{
        authorize_url: "https://example.com/auth",
        state: "st_abc",
        provider: "slack",
        client: client,
        data: %{"extra" => "val"}
      }

      assert flow.authorize_url == "https://example.com/auth"
      assert flow.state == "st_abc"
      assert flow.provider == "slack"
      assert flow.data == %{"extra" => "val"}
    end
  end

  # ---------------------------------------------------------------------------
  # wait_for_completion/2
  # ---------------------------------------------------------------------------

  describe "wait_for_completion/2" do
    test "returns {:ok, payload} when status=completed", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/egress/oauth/status", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{
            "status" => "completed",
            "secret_id" => "sec_oauth_1"
          })
        )
      end)

      flow = %OauthFlow{
        authorize_url: "https://github.com/oauth",
        state: "st_xyz",
        provider: "github",
        client: client
      }

      assert {:ok, %{"status" => "completed", "secret_id" => "sec_oauth_1"}} =
               OauthFlow.wait_for_completion(flow)
    end

    test "returns {:ok, payload} when status=ready", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/egress/oauth/status", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"status" => "ready"}))
      end)

      flow = %OauthFlow{
        authorize_url: "https://example.com/auth",
        state: "st_1",
        client: client
      }

      assert {:ok, %{"status" => "ready"}} = OauthFlow.wait_for_completion(flow)
    end

    test "returns {:error, reason} when status=failed", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/egress/oauth/status", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{"status" => "failed", "error" => "access denied"})
        )
      end)

      flow = %OauthFlow{
        authorize_url: "https://example.com/auth",
        state: "st_2",
        client: client
      }

      assert {:error, reason} = OauthFlow.wait_for_completion(flow)
      assert reason =~ "failed"
      assert reason =~ "access denied"
    end

    test "returns {:error, :timeout} when timeout_ms elapses", %{client: client} do
      # No Bypass handler — the client will actually fail with a connection error,
      # but we use a 0ms timeout so we exercise the timeout path without needing
      # real network activity
      flow = %OauthFlow{
        authorize_url: "https://example.com/auth",
        state: "st_timeout",
        client: client
      }

      assert {:error, :timeout} = OauthFlow.wait_for_completion(flow, timeout_ms: 0)
    end

    test "Secrets.connect/3 returns OauthFlow with correct fields",
         %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/egress/oauth/start", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{
            "authorize_url" => "https://slack.com/oauth/v2/authorize?state=sl_abc",
            "state" => "sl_abc"
          })
        )
      end)

      assert {:ok, flow} = Secrets.connect(client, "slack")
      assert %OauthFlow{} = flow
      assert flow.provider == "slack"
      assert flow.state == "sl_abc"
      assert String.starts_with?(flow.authorize_url, "https://slack.com")
    end
  end
end
