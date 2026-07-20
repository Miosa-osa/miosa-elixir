defmodule Miosa.WebSocketTest do
  use ExUnit.Case, async: false

  alias Miosa.TestWebSocketServer, as: Server

  test "preserves headers and query and handles all frame lifecycle behavior" do
    test_pid = self()

    server =
      Server.start(fn socket, request ->
        send(test_pid, {:request, request})
        Server.accept(socket, request, subprotocol: "miosa-test-v1")

        Server.send_frames(socket, [
          {:text, "one"},
          {:binary, <<0, 1, 2>>},
          {:fragment, :text, "frag"},
          {:continuation_end, "mented"},
          {:text, "two"},
          {:ping, "alive"}
        ])

        send(test_pid, {:client_frame, Server.recv_frame(socket)})
        Server.send_frame(socket, {:close, 1_007, "complete"})
        send(test_pid, {:client_close, Server.recv_frame(socket)})
      end)

    on_exit(fn -> Server.stop(server) end)

    assert {:ok, websocket} =
             Miosa.WebSocket.connect(
               "ws://127.0.0.1:#{server.port}/socket/path?tenant=t1&trace=a%2Fb",
               owner: self(),
               headers: [{"authorization", "Bearer secret"}, {"x-sdk-test", "yes"}],
               subprotocol: "miosa-test-v1"
             )

    monitor = Process.monitor(websocket)

    assert_receive {:request, request}
    assert request.target == "/socket/path?tenant=t1&trace=a%2Fb"
    assert request.headers["authorization"] == "Bearer secret"
    assert request.headers["x-sdk-test"] == "yes"
    assert request.headers["sec-websocket-protocol"] == "miosa-test-v1"

    assert_receive {:miosa_web_socket, ^websocket, {:frame, {:text, "one"}}}
    assert_receive {:miosa_web_socket, ^websocket, {:frame, {:binary, <<0, 1, 2>>}}}
    assert_receive {:miosa_web_socket, ^websocket, {:frame, {:text, "fragmented"}}}
    assert_receive {:miosa_web_socket, ^websocket, {:frame, {:text, "two"}}}
    assert_receive {:client_frame, {:ok, {:pong, "alive"}}}
    assert_receive {:miosa_web_socket, ^websocket, {:closed, 1_007, "complete"}}
    assert_receive {:client_close, {:ok, {:close, 1_007, "complete"}}}

    assert_receive {:DOWN, ^monitor, :process, ^websocket, :normal}
  end

  test "rejects a mismatched or missing negotiated subprotocol" do
    server =
      Server.start(fn socket, request ->
        Server.accept(socket, request, subprotocol: "wrong-v1")
        Process.sleep(100)
      end)

    on_exit(fn -> Server.stop(server) end)

    assert {:error, {:subprotocol_mismatch, ["wrong-v1"]}} =
             Miosa.WebSocket.connect("ws://127.0.0.1:#{server.port}/socket",
               subprotocol: "required-v1"
             )
  end

  test "enforces the inbound complete-message limit after fragmentation" do
    test_pid = self()

    server =
      Server.start(fn socket, request ->
        Server.accept(socket, request)

        Server.send_frames(socket, [
          {:fragment, :text, "1234"},
          {:continuation_end, "5678"}
        ])

        send(test_pid, {:limit_close, Server.recv_frame(socket)})
      end)

    on_exit(fn -> Server.stop(server) end)

    assert {:ok, websocket} =
             Miosa.WebSocket.connect("ws://127.0.0.1:#{server.port}/socket",
               owner: self(),
               max_message_size: 7
             )

    assert_receive {:miosa_web_socket, ^websocket, {:error, :message_too_large}}
    assert_receive {:limit_close, {:ok, {:close, 1_009, "message too large"}}}
    refute_receive {:miosa_web_socket, ^websocket, {:frame, _frame}}
  end

  test "reports an abrupt disconnect and terminates" do
    server =
      Server.start(fn socket, request ->
        Server.accept(socket, request)
        Server.close(socket)
      end)

    on_exit(fn -> Server.stop(server) end)

    assert {:ok, websocket} =
             Miosa.WebSocket.connect("ws://127.0.0.1:#{server.port}/socket", owner: self())

    assert_receive {:miosa_web_socket, ^websocket, {:error, %Mint.TransportError{}}}
    refute Process.alive?(websocket)
  end
end
