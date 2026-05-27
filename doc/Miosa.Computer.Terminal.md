# `Miosa.Computer.Terminal`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/computer/terminal.ex#L1)

PTY session management for a computer.

Maps to `POST /computers/:id/terminal` (create) and
`POST /computers/:id/pty/:session_id/resize` (resize).

# `create`

```elixir
@spec create(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Open a new PTY session (POST `/computers/:computer_id/terminal`).

## Options

  * `:cols` — Terminal column width.
  * `:rows` — Terminal row count.
  * `:shell` — Shell binary path (e.g. `"/bin/bash"`).
  * `:cwd` — Working directory inside the VM.
  * `:env` — Environment variables map.

# `resize`

```elixir
@spec resize(Miosa.Client.t(), String.t(), String.t(), pos_integer(), pos_integer()) ::
  Miosa.Client.result(map())
```

Resize an existing PTY session
(POST `/computers/:computer_id/pty/:session_id/resize`).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
