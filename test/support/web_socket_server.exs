defmodule Miosa.TestWebSocketServer do
  @moduledoc false

  import Bitwise

  @magic "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

  def start(handler) when is_function(handler, 2) do
    caller = self()
    pid = spawn(fn -> listen(caller, handler) end)

    receive do
      {:listening, ^pid, port} -> %{pid: pid, port: port}
    after
      1_000 -> raise "WebSocket test server failed to start"
    end
  end

  def stop(%{pid: pid}) do
    Process.exit(pid, :kill)
    :ok
  end

  def accept(socket, request, opts \\ []) do
    protocol = Keyword.get(opts, :subprotocol)

    headers =
      [
        "HTTP/1.1 101 Switching Protocols",
        "upgrade: websocket",
        "connection: Upgrade",
        "sec-websocket-accept: #{accept_key(request.headers["sec-websocket-key"])}"
      ] ++ if(protocol, do: ["sec-websocket-protocol: #{protocol}"], else: [])

    :gen_tcp.send(socket, Enum.join(headers, "\r\n") <> "\r\n\r\n")
  end

  def reject(socket, status \\ 404) do
    body = Jason.encode!(%{"error" => "websocket unavailable"})

    :gen_tcp.send(
      socket,
      "HTTP/1.1 #{status} Rejected\r\ncontent-type: application/json\r\ncontent-length: #{byte_size(body)}\r\nconnection: close\r\n\r\n#{body}"
    )
  end

  def send_frame(socket, frame), do: :gen_tcp.send(socket, encode_frame(frame))

  def send_frames(socket, frames) do
    :gen_tcp.send(socket, Enum.map(frames, &encode_frame/1))
  end

  def recv_frame(socket, timeout \\ 1_000) do
    with {:ok, <<fin::1, _rsv::3, opcode::4, masked::1, length::7>>} <- recv(socket, 2, timeout),
         {:ok, length} <- recv_length(socket, length, timeout),
         {:ok, mask} <- recv_mask(socket, masked, timeout),
         {:ok, payload} <- recv(socket, length, timeout) do
      {:ok, decode_frame(fin, opcode, apply_mask(payload, mask))}
    end
  end

  def close(socket), do: :gen_tcp.close(socket)

  defp listen(caller, handler) do
    {:ok, listener} =
      :gen_tcp.listen(0, [
        :binary,
        packet: :raw,
        active: false,
        reuseaddr: true,
        ip: {127, 0, 0, 1}
      ])

    {:ok, port} = :inet.port(listener)
    send(caller, {:listening, self(), port})
    accept_loop(listener, handler)
  end

  defp accept_loop(listener, handler) do
    case :gen_tcp.accept(listener) do
      {:ok, socket} ->
        worker = spawn(fn -> connection_loop(handler) end)
        :ok = :gen_tcp.controlling_process(socket, worker)
        send(worker, {:socket, socket})
        accept_loop(listener, handler)

      {:error, :closed} ->
        :ok
    end
  end

  defp connection_loop(handler) do
    receive do
      {:socket, socket} ->
        case recv_request(socket, "") do
          {:ok, request} -> handler.(socket, request)
          {:error, _reason} -> :ok
        end
    after
      5_000 -> :ok
    end
  end

  defp recv_request(socket, acc) do
    case :binary.match(acc, "\r\n\r\n") do
      {index, 4} ->
        <<head::binary-size(index), _separator::binary-size(4), _rest::binary>> = acc
        {:ok, parse_request(head)}

      :nomatch ->
        case :gen_tcp.recv(socket, 0, 1_000) do
          {:ok, data} -> recv_request(socket, acc <> data)
          error -> error
        end
    end
  end

  defp parse_request(head) do
    [request_line | header_lines] = String.split(head, "\r\n")
    [method, target, _version] = String.split(request_line, " ", parts: 3)

    headers =
      Map.new(header_lines, fn line ->
        [name, value] = String.split(line, ":", parts: 2)
        {String.downcase(name), String.trim(value)}
      end)

    %{method: method, target: target, headers: headers}
  end

  defp accept_key(key) do
    :crypto.hash(:sha, key <> @magic) |> Base.encode64()
  end

  defp encode_frame({:text, data}), do: encode_frame(1, 1, data)
  defp encode_frame({:binary, data}), do: encode_frame(1, 2, data)
  defp encode_frame({:fragment, :text, data}), do: encode_frame(0, 1, data)
  defp encode_frame({:fragment, :binary, data}), do: encode_frame(0, 2, data)
  defp encode_frame({:continuation, data}), do: encode_frame(0, 0, data)
  defp encode_frame({:continuation_end, data}), do: encode_frame(1, 0, data)
  defp encode_frame({:ping, data}), do: encode_frame(1, 9, data)
  defp encode_frame({:pong, data}), do: encode_frame(1, 10, data)
  defp encode_frame({:close, code, reason}), do: encode_frame(1, 8, <<code::16, reason::binary>>)

  defp encode_frame(fin, opcode, data) when byte_size(data) <= 125 do
    <<fin::1, 0::3, opcode::4, 0::1, byte_size(data)::7, data::binary>>
  end

  defp encode_frame(fin, opcode, data) when byte_size(data) <= 65_535 do
    <<fin::1, 0::3, opcode::4, 0::1, 126::7, byte_size(data)::16, data::binary>>
  end

  defp recv_length(_socket, length, _timeout) when length <= 125, do: {:ok, length}

  defp recv_length(socket, 126, timeout) do
    with {:ok, <<length::16>>} <- recv(socket, 2, timeout), do: {:ok, length}
  end

  defp recv_length(socket, 127, timeout) do
    with {:ok, <<length::64>>} <- recv(socket, 8, timeout), do: {:ok, length}
  end

  defp recv_mask(socket, 1, timeout), do: recv(socket, 4, timeout)
  defp recv_mask(_socket, 0, _timeout), do: {:ok, nil}

  defp recv(_socket, 0, _timeout), do: {:ok, <<>>}
  defp recv(socket, length, timeout), do: :gen_tcp.recv(socket, length, timeout)

  defp apply_mask(payload, nil), do: payload

  defp apply_mask(payload, mask) do
    mask_bytes = :binary.bin_to_list(mask)

    payload
    |> :binary.bin_to_list()
    |> Enum.with_index()
    |> Enum.map(fn {byte, index} -> bxor(byte, Enum.at(mask_bytes, rem(index, 4))) end)
    |> :binary.list_to_bin()
  end

  defp decode_frame(_fin, 1, payload), do: {:text, payload}
  defp decode_frame(_fin, 2, payload), do: {:binary, payload}
  defp decode_frame(_fin, 8, <<code::16, reason::binary>>), do: {:close, code, reason}
  defp decode_frame(_fin, 8, <<>>), do: {:close, nil, ""}
  defp decode_frame(_fin, 9, payload), do: {:ping, payload}
  defp decode_frame(_fin, 10, payload), do: {:pong, payload}
end
