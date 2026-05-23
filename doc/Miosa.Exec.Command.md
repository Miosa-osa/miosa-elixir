# `Miosa.Exec.Command`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/exec/command.ex#L1)

A GenServer holding a long-lived interactive command session over WebSocket.

Obtained via `Miosa.Exec.spawn/3`. Provides stdin/stdout interaction and
terminal resize for PTY-based commands.

The underlying WebSocket is managed via `:gun`. The GenServer owns the
connection and shuts it down on termination.

## Example

    {:ok, cmd} = Miosa.Exec.spawn(client, computer_id, "bash")

    :ok = Miosa.Exec.Command.send_stdin(cmd, "ls -la\n")
    :ok = Miosa.Exec.Command.resize(cmd, 120, 40)

    # Block until the command exits (or timeout)
    {:ok, exit_code} = Miosa.Exec.Command.await(cmd, 30_000)

# `t`

```elixir
@type t() :: pid()
```

# `await`

```elixir
@spec await(t(), pos_integer()) :: {:ok, integer()} | {:error, :timeout | term()}
```

Blocks until the command exits and returns `{:ok, exit_code}`.

Returns `{:error, :timeout}` if the command does not exit within `timeout_ms`.
The GenServer process is stopped after `await/2` returns.

# `child_spec`

Returns a specification to start this module under a supervisor.

See `Supervisor`.

# `close_stdin`

```elixir
@spec close_stdin(t()) :: :ok | {:error, term()}
```

Signals stdin EOF to the command (closes the write half of the WebSocket).

# `resize`

```elixir
@spec resize(t(), pos_integer(), pos_integer()) :: :ok | {:error, term()}
```

Sends a terminal resize event (SIGWINCH) to the running command.

Only meaningful for PTY-based commands (those started with `pty: true`).

# `send_stdin`

```elixir
@spec send_stdin(t(), String.t()) :: :ok | {:error, term()}
```

Sends data to the command's stdin.

`data` should be a binary string (may include newlines).
Returns `:ok` immediately; delivery is async over the WebSocket.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
