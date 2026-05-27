# `Miosa.Sandbox.Processes`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/sandbox/processes.ex#L1)

Background process management for a sandbox.

Wraps:
  * `POST   /sandboxes/:id/processes`              — start/4
  * `GET    /sandboxes/:id/processes`              — list/2
  * `DELETE /sandboxes/:id/processes/:pid`         — kill/3
  * `POST   /sandboxes/:id/processes/:pid/stdin`   — send_stdin/4

# `kill`

```elixir
@spec kill(Miosa.Client.t(), String.t(), String.t()) ::
  :ok | {:error, Miosa.Error.t()}
```

Kill a background process by its PID
(DELETE `/sandboxes/:sandbox_id/processes/:pid`).

# `list`

```elixir
@spec list(Miosa.Client.t(), String.t()) :: Miosa.Client.result(list())
```

List all running background processes in the sandbox
(GET `/sandboxes/:sandbox_id/processes`).

# `send_stdin`

```elixir
@spec send_stdin(Miosa.Client.t(), String.t(), String.t(), String.t()) ::
  Miosa.Client.result(map())
```

Send data to the stdin of a running background process
(POST `/sandboxes/:sandbox_id/processes/:pid/stdin`).

# `start`

```elixir
@spec start(Miosa.Client.t(), String.t(), String.t(), map()) ::
  Miosa.Client.result(map())
```

Start a background process in the sandbox
(POST `/sandboxes/:sandbox_id/processes`).

## Options map keys

  * `"cwd"` — Working directory for the process.
  * `"env"` — Environment variables map.
  * `"timeout"` — Process timeout in seconds.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
