defmodule Miosa.Sandboxes.WaitUntilReadyTest do
  use ExUnit.Case, async: false

  alias Miosa.Sandboxes

  setup do
    bypass = Bypass.open()
    client = Miosa.client("msk_u_test", base_url: "http://localhost:#{bypass.port}/api/v1")
    {:ok, bypass: bypass, client: client}
  end

  describe "wait_until_ready/3 (stream: true)" do
    test "returns {:ok, true} on SSE event: ready", %{bypass: bypass, client: client} do
      Bypass.expect_once(
        bypass,
        "GET",
        "/api/v1/sandboxes/sbx_1/readiness/stream",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_content_type("text/event-stream")
          |> Plug.Conn.send_chunked(200)
          |> chunk_or_close(": keepalive\n\n")
          |> chunk_or_close("event: ready\ndata: {\"ready_at\":\"2026-05-18T00:00:00Z\"}\n\n")
        end
      )

      assert {:ok, true} = Sandboxes.wait_until_ready(client, "sbx_1", timeout: 5)
    end

    test "returns {:ok, false} on SSE event: timeout", %{bypass: bypass, client: client} do
      Bypass.expect_once(
        bypass,
        "GET",
        "/api/v1/sandboxes/sbx_2/readiness/stream",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_content_type("text/event-stream")
          |> Plug.Conn.send_chunked(200)
          |> chunk_or_close("event: timeout\ndata: {\"reason\":\"not_ready_after_30s\"}\n\n")
        end
      )

      assert {:ok, false} = Sandboxes.wait_until_ready(client, "sbx_2", timeout: 5)
    end

    test "falls back to polling and returns {:ok, true} when SSE returns 404",
         %{bypass: bypass, client: client} do
      Bypass.expect_once(
        bypass,
        "GET",
        "/api/v1/sandboxes/sbx_3/readiness/stream",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.send_resp(404, Jason.encode!(%{"error" => "endpoint not implemented"}))
        end
      )

      poll_count = :counters.new(1, [])

      Bypass.expect(
        bypass,
        "GET",
        "/api/v1/sandboxes/sbx_3/readiness",
        fn conn ->
          n = :counters.add(poll_count, 1, 1)
          # The first poll returns not-ready, subsequent polls return ready.
          ready = :counters.get(poll_count, 1) >= 2
          _ = n

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.send_resp(200, Jason.encode!(%{"data" => %{"ready" => ready}}))
        end
      )

      assert {:ok, true} = Sandboxes.wait_until_ready(client, "sbx_3", timeout: 3)
    end
  end

  describe "wait_until_ready/3 (stream: false)" do
    test "polls /readiness only and returns {:ok, true} once ready",
         %{bypass: bypass, client: client} do
      Bypass.expect_once(
        bypass,
        "GET",
        "/api/v1/sandboxes/sbx_4/readiness",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.send_resp(200, Jason.encode!(%{"data" => %{"ready" => true}}))
        end
      )

      # No SSE handler registered — if the SDK tried, Bypass would fail the test.
      assert {:ok, true} =
               Sandboxes.wait_until_ready(client, "sbx_4", timeout: 2, stream: false)
    end
  end

  # Helper — Bypass + Plug.Conn.chunk returns {:ok, conn} | {:error, _}. We treat
  # an error (client closed the connection) as a normal end-of-stream by returning
  # the original conn so subsequent calls are no-ops.
  defp chunk_or_close(conn, data) do
    case Plug.Conn.chunk(conn, data) do
      {:ok, conn} -> conn
      {:error, _reason} -> conn
    end
  end
end
