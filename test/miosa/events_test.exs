defmodule Miosa.EventsTest do
  use ExUnit.Case, async: true

  alias Miosa.Events

  setup do
    bypass = Bypass.open()
    client = Miosa.client("msk_u_test", base_url: "http://localhost:#{bypass.port}/api/v1")
    {:ok, bypass: bypass, client: client, cid: "comp_abc"}
  end

  describe "subscribe/2" do
    test "returns an Enumerable (Stream)", %{client: client, cid: cid} do
      stream = Events.subscribe(client, cid)

      # Verify the return value implements Enumerable — the contract of subscribe/2
      assert Enumerable.impl_for(stream) != nil
    end

    test "halts gracefully when the server returns a non-200 status", %{
      bypass: bypass,
      client: client,
      cid: cid
    } do
      # If the SSE endpoint returns an error, the stream should halt
      # rather than blocking forever. We verify that Enum.take returns [] quickly.
      Bypass.expect_once(bypass, "GET", "/api/v1/computers/comp_abc/events", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(404, Jason.encode!(%{"error" => "Not found"}))
      end)

      # With a short timeout, the stream should halt promptly (error from SSE task).
      events = Events.subscribe(client, cid, timeout: 3_000) |> Enum.take(5)
      assert events == []
    end
  end
end
