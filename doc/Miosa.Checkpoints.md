# `Miosa.Checkpoints`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/checkpoints.ex#L1)

Create and restore disk snapshots (checkpoints) of MIOSA computers.

A checkpoint captures the full disk state of a computer at a point in time.
Restoring a checkpoint rolls the computer back to that exact state.

## Example

    {:ok, snap} = Miosa.Checkpoints.create(client, computer_id, %{
      name: "before-deploy"
    })

    {:ok, snaps} = Miosa.Checkpoints.list(client, computer_id)
    {:ok, snap} = Miosa.Checkpoints.get(client, computer_id, snap.id)

    # Restore with optional SSE progress streaming
    :ok = Miosa.Checkpoints.restore(client, computer_id, snap.id)

    # Stream restore progress events
    events = Miosa.Checkpoints.restore_stream(client, computer_id, snap.id)
    Enum.each(events, fn event -> IO.inspect(event) end)

    :ok = Miosa.Checkpoints.delete(client, computer_id, snap.id)

# `create_params`

```elixir
@type create_params() :: %{
  optional(:name) =&gt; String.t(),
  optional(:description) =&gt; String.t()
}
```

# `create`

```elixir
@spec create(Miosa.Client.t(), String.t(), create_params()) ::
  Miosa.Client.result(Miosa.Types.Snapshot.t())
```

Creates a new checkpoint (snapshot) of a computer's disk state.

The computer should be stopped or in a consistent state before snapshotting.

## Params

  * `:name` — Optional display name.
  * `:description` — Optional description of what this snapshot represents.

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t(), String.t()) ::
  :ok | {:error, Miosa.Error.t()}
```

Deletes a checkpoint permanently.

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t(), String.t()) ::
  Miosa.Client.result(Miosa.Types.Snapshot.t())
```

Fetches a single checkpoint by ID.

# `list`

```elixir
@spec list(Miosa.Client.t(), String.t()) ::
  Miosa.Client.result([Miosa.Types.Snapshot.t()])
```

Lists all checkpoints for a computer, ordered by creation time (newest first).

# `restore`

```elixir
@spec restore(Miosa.Client.t(), String.t(), String.t()) ::
  :ok | {:error, Miosa.Error.t()}
```

Restores a computer to a checkpoint state (fire-and-forget).

The API will stop the computer (if running), restore the disk, and restart it.
Returns `:ok` once the restore request is accepted.

Use `restore_stream/3` to receive incremental progress events via an Elixir
`Stream`.

# `restore_stream`

```elixir
@spec restore_stream(Miosa.Client.t(), String.t(), String.t()) :: Enumerable.t()
```

Restores a checkpoint and returns a `Stream` of progress events.

Each element yielded by the stream is a map with at least `:event` and
`:data` keys. The stream ends when the restore completes or fails.

## Example

    stream = Miosa.Checkpoints.restore_stream(client, computer_id, snap_id)
    Enum.each(stream, fn %{event: e, data: d} -> IO.puts("#{e}: #{inspect(d)}") end)

---

*Consult [api-reference.md](api-reference.md) for complete listing*
