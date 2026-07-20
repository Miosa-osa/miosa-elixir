defmodule Miosa.WebSocketConsumersTest do
  use ExUnit.Case, async: false

  alias Miosa.{Exec, Exec.Command, Sandboxes.Audit}
  alias Miosa.TestWebSocketServer, as: Server

  test "command sends authorization, preserves base query, exchanges frames, and exits" do
    test_pid = self()

    server =
      Server.start(fn socket, request ->
        send(test_pid, {:command_request, request})
        Server.accept(socket, request)
        send(test_pid, {:stdin, Server.recv_frame(socket)})
        send(test_pid, {:resize, Server.recv_frame(socket)})
        Server.send_frames(socket, [{:text, "stdout"}, {:binary, <<1, 2>>}])
        Server.send_frame(socket, {:close, 1_007, "exit"})
      end)

    on_exit(fn -> Server.stop(server) end)

    client =
      Miosa.client("msk_u_command",
        base_url: "http://127.0.0.1:#{server.port}/api/v1?tenant=tenant-1"
      )

    assert {:ok, command} = Exec.spawn(client, "comp_abc", "printf 'a b'", pty: true)
    assert_receive {:command_request, request}
    assert request.headers["authorization"] == "Bearer msk_u_command"

    assert %URI{path: "/api/v1/computers/comp_abc/exec/ws", query: query} =
             URI.parse(request.target)

    assert URI.decode_query(query) == %{
             "command" => "printf 'a b'",
             "pty" => "true",
             "tenant" => "tenant-1"
           }

    assert eventually(fn -> Command.send_stdin(command, "input\n") end) == :ok
    assert :ok = Command.resize(command, 120, 40)
    assert_receive {:stdin, {:ok, {:text, "input\n"}}}
    assert_receive {:resize, {:ok, {:text, resize}}}
    assert Jason.decode!(resize) == %{"type" => "resize", "cols" => 120, "rows" => 40}
    assert {:ok, 7} = Command.await(command, 1_000)
    refute Process.alive?(command)
  end

  test "command await timeout closes the WebSocket and stops the command" do
    test_pid = self()

    server =
      Server.start(fn socket, request ->
        Server.accept(socket, request)
        send(test_pid, :command_connected)
        send(test_pid, {:timeout_close, Server.recv_frame(socket, 1_000)})
      end)

    on_exit(fn -> Server.stop(server) end)

    client = Miosa.client("msk_u_timeout", base_url: "http://127.0.0.1:#{server.port}/api/v1")
    assert {:ok, command} = Exec.spawn(client, "comp_abc", "sleep 60")
    assert_receive :command_connected
    assert {:error, :timeout} = Command.await(command, 25)
    assert_receive {:timeout_close, {:ok, {:close, 1_000, ""}}}
    refute Process.alive?(command)
  end

  test "audit validates query and subprotocol, decodes frames, and closes on early stream halt" do
    test_pid = self()

    server =
      Server.start(fn socket, request ->
        send(test_pid, {:audit_request, request})
        Server.accept(socket, request, subprotocol: "miosa-egress-audit-v1")

        first = Jason.encode!(%{"id" => "evt_1"})
        second = Jason.encode!(%{"id" => "evt_2"})

        Server.send_frames(socket, [
          {:fragment, :text, binary_part(first, 0, 5)},
          {:continuation_end, binary_part(first, 5, byte_size(first) - 5)},
          {:binary, second}
        ])

        send(test_pid, {:audit_close, Server.recv_frame(socket)})
      end)

    on_exit(fn -> Server.stop(server) end)

    client =
      Miosa.client("msk_u_audit",
        base_url: "http://127.0.0.1:#{server.port}/api/v1?tenant=t1"
      )

    assert {:ok, stream} = Audit.tail("sandbox/a", client)
    assert_receive {:audit_request, request}
    assert request.headers["sec-websocket-protocol"] == "miosa-egress-audit-v1"

    assert %URI{path: "/api/v1/egress/audit/resource/sandbox%2Fa", query: query} =
             URI.parse(request.target)

    assert URI.decode_query(query) == %{"tenant" => "t1", "token" => "msk_u_audit"}
    assert Enum.take(stream, 2) == [%{"id" => "evt_1"}, %{"id" => "evt_2"}]
    assert_receive {:audit_close, {:ok, {:close, 1_000, ""}}}
  end

  test "audit falls back to REST when the exact subprotocol is rejected" do
    test_pid = self()

    server =
      Server.start(fn socket, request ->
        send(test_pid, {:fallback_request, request})

        if request.headers["upgrade"] == "websocket" do
          Server.accept(socket, request, subprotocol: "not-miosa-audit")
        else
          body = Jason.encode!(%{"data" => [%{"id" => "rest_evt"}]})

          :gen_tcp.send(
            socket,
            "HTTP/1.1 200 OK\r\ncontent-type: application/json\r\ncontent-length: #{byte_size(body)}\r\nconnection: close\r\n\r\n#{body}"
          )
        end
      end)

    on_exit(fn -> Server.stop(server) end)

    client = Miosa.client("msk_u_fallback", base_url: "http://127.0.0.1:#{server.port}/api/v1")
    assert {:ok, stream} = Audit.tail("sb_1", client, poll_interval_ms: 0)
    assert Enum.take(stream, 1) == [%{"id" => "rest_evt"}]

    assert_receive {:fallback_request, %{headers: %{"upgrade" => "websocket"}}}
    assert_receive {:fallback_request, %{method: "GET", target: rest_target}}
    assert String.starts_with?(rest_target, "/api/v1/egress/audit?")
  end

  test "audit does not fall back after an accepted WebSocket disconnects" do
    test_pid = self()

    server =
      Server.start(fn socket, request ->
        send(test_pid, {:disconnect_request, request})
        Server.accept(socket, request, subprotocol: "miosa-egress-audit-v1")
        Server.close(socket)
      end)

    on_exit(fn -> Server.stop(server) end)

    client = Miosa.client("msk_u_disconnect", base_url: "http://127.0.0.1:#{server.port}/api/v1")
    assert {:ok, stream} = Audit.tail("sb_1", client)
    assert Enum.to_list(stream) == []
    assert_receive {:disconnect_request, %{headers: %{"upgrade" => "websocket"}}}
    refute_receive {:disconnect_request, _request}, 100
  end

  defp eventually(fun, attempts \\ 50)
  defp eventually(fun, 0), do: fun.()

  defp eventually(fun, attempts) do
    case fun.() do
      {:error, :not_running} ->
        Process.sleep(5)
        eventually(fun, attempts - 1)

      result ->
        result
    end
  end
end
