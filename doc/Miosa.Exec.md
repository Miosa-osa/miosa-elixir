# `Miosa.Exec`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/exec.ex#L1)

Execute commands and scripts inside a running MIOSA computer.

Both Bash and Python execution are supported. Commands run with the default
user's environment inside the VM.

## Example

    {:ok, result} = Miosa.Exec.bash(client, computer_id, "ls -la /home/user")
    IO.puts(result.output)
    IO.puts("Exit code: #{result.exit_code}")

    {:ok, result} = Miosa.Exec.python(client, computer_id, """
      import json
      data = {"hello": "world"}
      print(json.dumps(data))
    """)

# `bash`

```elixir
@spec bash(Miosa.Client.t(), String.t(), String.t(), keyword()) ::
  Miosa.Client.result(Miosa.Types.ExecResult.t())
```

Executes a Bash command inside the computer.

## Options

  * `:timeout` — Execution timeout in milliseconds. Defaults to `30_000`.
  * `:working_dir` — Working directory for the command. Defaults to `"/home/user"`.
  * `:env` — Map of additional environment variables.

## Returns

`{:ok, result}` with an `ExecResult` containing `:output`, `:stdout`,
`:stderr`, and `:exit_code`. On API error, returns `{:error, reason}`.

# `bash!`

```elixir
@spec bash!(Miosa.Client.t(), String.t(), String.t(), keyword()) ::
  Miosa.Types.ExecResult.t()
```

Convenience wrapper: runs bash and raises `Miosa.Error` on failure.

Returns the `ExecResult` directly (not wrapped in `{:ok, _}`).

# `python`

```elixir
@spec python(Miosa.Client.t(), String.t(), String.t(), keyword()) ::
  Miosa.Client.result(Miosa.Types.ExecResult.t())
```

Executes a Python script inside the computer.

The script runs with the system Python 3 interpreter. Common packages
(requests, numpy, pandas, etc.) may be pre-installed depending on the
computer template.

## Options

  * `:timeout` — Execution timeout in milliseconds. Defaults to `30_000`.
  * `:working_dir` — Working directory. Defaults to `"/home/user"`.
  * `:env` — Map of additional environment variables.

# `python!`

```elixir
@spec python!(Miosa.Client.t(), String.t(), String.t(), keyword()) ::
  Miosa.Types.ExecResult.t()
```

Convenience wrapper: runs python and raises `Miosa.Error` on failure.

Returns the `ExecResult` directly (not wrapped in `{:ok, _}`).

# `spawn`

```elixir
@spec spawn(Miosa.Client.t(), String.t(), String.t(), keyword()) ::
  {:ok, Miosa.Exec.Command.t()} | {:error, term()}
```

Spawns an interactive command session over WebSocket and returns a
`Miosa.Exec.Command` GenServer PID.

The returned PID represents a live WebSocket connection to the computer.
Use `Miosa.Exec.Command.send_stdin/2`, `close_stdin/1`, `resize/3`, and
`await/2` to interact with the running process.

The GenServer owns the WebSocket connection and terminates it on shutdown.
Callers should always call `Miosa.Exec.Command.await/2` to drain the session
and ensure the underlying connection is cleaned up.

## Options

  * `:pty` — Allocate a pseudo-terminal. Required for interactive programs
    like shells. Defaults to `false`.

## Example

    {:ok, cmd} = Miosa.Exec.spawn(client, computer_id, "bash", pty: true)
    :ok = Miosa.Exec.Command.send_stdin(cmd, "echo hello\n")
    :ok = Miosa.Exec.Command.send_stdin(cmd, "exit\n")
    {:ok, 0} = Miosa.Exec.Command.await(cmd, 5_000)

---

*Consult [api-reference.md](api-reference.md) for complete listing*
