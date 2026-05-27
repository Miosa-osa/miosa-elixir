defmodule Miosa.Events do
  @moduledoc """
  Subscribe to real-time computer lifecycle events via SSE.

  `subscribe/2` returns a `Stream` that yields `Miosa.Types.ComputerEvent`
  structs as they arrive. The stream is lazy and pulls events from the SSE
  connection on demand.

  Choosing a `Stream` over a GenServer fan-out is idiomatic for Elixir
  consumers: callers can `Enum.take/2`, pipe into `Flow`, or simply
  `Stream.run/1` — all standard `Enumerable` operations apply. A GenServer
  is unnecessary unless the caller needs concurrent fan-out to multiple
  processes, which can be achieved by spawning a `Task` that runs the stream
  and uses `Process.send/2` to forward events — a pattern the caller controls
  without SDK coupling.

  ## Example

      stream = Miosa.Events.subscribe(client, computer_id)

      # Process events until the stream ends (server closes connection)
      Enum.each(stream, fn event ->
        IO.inspect(event)
      end)

      # Async: spawn a Task and receive events as messages
      parent = self()
      Task.start(fn ->
        Miosa.Events.subscribe(client, computer_id)
        |> Enum.each(fn event -> send(parent, {:computer_event, event}) end)
      end)

  """

  alias Miosa.{Client, Types}

  @type subscribe_opts :: [
          timeout: pos_integer()
        ]

  @doc """
  Returns a `Stream` of `Miosa.Types.ComputerEvent` structs for the given computer.

  The stream connects to the server-sent events endpoint for the computer and
  yields events as they arrive. The stream ends when the SSE connection closes
  (server-side) or the caller stops consuming it.

  ## Options

    * `:timeout` — Per-event receive timeout in milliseconds. Defaults to `300_000`.

  """
  @spec subscribe(Client.t(), String.t(), subscribe_opts()) :: Enumerable.t()
  def subscribe(%Client{} = client, computer_id, opts \\ [])
      when is_binary(computer_id) do
    timeout = Keyword.get(opts, :timeout, 300_000)
    path = "/computers/#{computer_id}/events"
    parent = self()

    Stream.resource(
      fn ->
        Task.start(fn ->
          result =
            Client.stream_sse(client, path, fn event ->
              send(parent, {:computer_event, event})
            end)

          send(parent, {:events_done, result})
        end)

        :streaming
      end,
      fn state ->
        case state do
          :streaming ->
            receive do
              {:computer_event, %{type: event_type, data: data_str}} ->
                event = Types.ComputerEvent.from_sse(to_string(event_type), data_str)
                {[event], :streaming}

              {:events_done, :ok} ->
                {:halt, :done}

              {:events_done, {:error, reason}} ->
                {:halt, {:error, reason}}
            after
              timeout ->
                {:halt, {:error, :timeout}}
            end

          _ ->
            {:halt, state}
        end
      end,
      fn _state -> :ok end
    )
  end

  @doc """
  Stream tenant-wide events over SSE.

  GET `/api/v1/events/stream?types=<comma-separated>`

  Returns a `Stream` of raw SSE event maps `%{type: _, data: _}`.

  ## Options

    * `:types`   — list of event type globs, e.g. `["sandbox.*", "webhook.delivered"]`.
      Defaults to all events.
    * `:timeout` — per-event receive timeout in milliseconds. Defaults to `300_000`.

  ## Example

      Miosa.Events.stream(client, types: ["sandbox.*"])
      |> Enum.each(&IO.inspect/1)
  """
  @spec stream(Client.t(), keyword()) :: Enumerable.t()
  def stream(%Client{} = client, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 300_000)
    types = Keyword.get(opts, :types, [])

    qs =
      if types == [] do
        ""
      else
        "?types=#{URI.encode_www_form(Enum.join(types, ","))}"
      end

    path = "/events/stream#{qs}"
    parent = self()

    Stream.resource(
      fn ->
        Task.start(fn ->
          result =
            Client.stream_sse(client, path, fn event ->
              send(parent, {:tenant_event, event})
            end)

          send(parent, {:events_done, result})
        end)

        :streaming
      end,
      fn state ->
        case state do
          :streaming ->
            receive do
              {:tenant_event, event} ->
                {[event], :streaming}

              {:events_done, :ok} ->
                {:halt, :done}

              {:events_done, {:error, reason}} ->
                {:halt, {:error, reason}}
            after
              timeout ->
                {:halt, {:error, :timeout}}
            end

          _ ->
            {:halt, state}
        end
      end,
      fn _state -> :ok end
    )
  end

end
