# `Miosa.Events`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/events.ex#L1)

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

# `subscribe_opts`

```elixir
@type subscribe_opts() :: [{:timeout, pos_integer()}]
```

# `subscribe`

```elixir
@spec subscribe(Miosa.Client.t(), String.t(), subscribe_opts()) :: Enumerable.t()
```

Returns a `Stream` of `Miosa.Types.ComputerEvent` structs for the given computer.

The stream connects to the server-sent events endpoint for the computer and
yields events as they arrive. The stream ends when the SSE connection closes
(server-side) or the caller stops consuming it.

## Options

  * `:timeout` — Per-event receive timeout in milliseconds. Defaults to `300_000`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
