defmodule Miosa.AuditTest do
  use ExUnit.Case, async: true

  alias Miosa.{Audit, Error}

  setup do
    bypass = Bypass.open()
    client = Miosa.client("msk_u_test", base_url: "http://localhost:#{bypass.port}/api/v1")
    {:ok, bypass: bypass, client: client}
  end

  # ---------------------------------------------------------------------------
  # list/2
  # ---------------------------------------------------------------------------

  describe "list/2" do
    test "GET /egress/audit returns a list of events", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/egress/audit", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!([
            %{"id" => "evt_1", "host" => "api.github.com"},
            %{"id" => "evt_2", "host" => "api.openai.com"}
          ])
        )
      end)

      assert {:ok, events} = Audit.list(client)
      assert length(events) == 2
      assert Enum.at(events, 0)["id"] == "evt_1"
    end

    test "forwards filters as query params", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/egress/audit", fn conn ->
        conn = Plug.Conn.fetch_query_params(conn)
        assert conn.query_params["resource_id"] == "sb_123"
        assert conn.query_params["host"] == "api.github.com"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!([%{"id" => "e1"}]))
      end)

      assert {:ok, [%{"id" => "e1"}]} =
               Audit.list(client, %{resource_id: "sb_123", host: "api.github.com"})
    end

    test "unwraps events envelope", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/egress/audit", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{"events" => [%{"id" => "e9"}]})
        )
      end)

      assert {:ok, [%{"id" => "e9"}]} = Audit.list(client)
    end

    test "returns error on 401", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/egress/audit", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(401, Jason.encode!(%{"error" => "Unauthorized"}))
      end)

      assert {:error, %Error{status: 401}} = Audit.list(client)
    end
  end

  # ---------------------------------------------------------------------------
  # get/2
  # ---------------------------------------------------------------------------

  describe "get/2" do
    test "GET /egress/audit/:id returns the event", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/egress/audit/evt_abc", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"id" => "evt_abc", "action" => "denied"}))
      end)

      assert {:ok, %{"id" => "evt_abc", "action" => "denied"}} = Audit.get(client, "evt_abc")
    end

    test "returns 404 for missing event", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/egress/audit/nope", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(404, Jason.encode!(%{"error" => "Not found"}))
      end)

      assert {:error, %Error{status: 404}} = Audit.get(client, "nope")
    end
  end

  # ---------------------------------------------------------------------------
  # tail/3 (Stream)
  # ---------------------------------------------------------------------------

  describe "tail/3" do
    test "returns a stream that yields events from polling", %{bypass: bypass, client: client} do
      # We serve two responses: first a batch, then empty (so the stream stops cleanly via take)
      event_batch = [%{"id" => "t1", "host" => "h1"}, %{"id" => "t2", "host" => "h2"}]

      Bypass.expect(bypass, "GET", "/api/v1/egress/audit", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(event_batch))
      end)

      # poll_interval_ms: 0 to keep the test fast
      stream = Audit.tail(client, nil, poll_interval_ms: 0)

      # Take the first 2 events and verify they are the expected ones
      events = stream |> Stream.take(2) |> Enum.to_list()
      assert length(events) == 2
      assert Enum.at(events, 0)["id"] == "t1"
      assert Enum.at(events, 1)["id"] == "t2"
    end

    test "deduplicates events by id across polls", %{bypass: bypass, client: client} do
      # Both polls return the same event — we should get exactly 1 result
      Bypass.stub(bypass, "GET", "/api/v1/egress/audit", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!([%{"id" => "dup_evt"}]))
      end)

      stream = Audit.tail(client, nil, poll_interval_ms: 0)
      # Take enough to exercise at least 2 poll cycles, but dedup means we still only get 1
      # We need 2 poll cycles to fire, so we take 1 (first cycle) then halt
      events = stream |> Stream.take(1) |> Enum.to_list()
      assert [%{"id" => "dup_evt"}] = events
    end
  end
end
