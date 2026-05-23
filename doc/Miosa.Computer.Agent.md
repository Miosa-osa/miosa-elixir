# `Miosa.Computer.Agent`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/computer/agent.ex#L1)

Computer-Use Agent (CUA) session management for a computer.

Wraps:
  * `POST   /computers/:id/cua/sessions`          — run/4
  * `GET    /computers/:id/cua/sessions`          — list/2
  * `GET    /computers/:id/cua/sessions/:sid`     — get/3
  * `DELETE /computers/:id/cua/sessions/:sid`     — cancel/3

# `cancel`

```elixir
@spec cancel(Miosa.Client.t(), String.t(), String.t()) ::
  :ok | {:error, Miosa.Error.t()}
```

Cancel a running CUA session
(DELETE `/computers/:computer_id/cua/sessions/:session_id`).

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t(), String.t()) :: Miosa.Client.result(map())
```

Retrieve a single CUA session by ID
(GET `/computers/:computer_id/cua/sessions/:session_id`).

# `list`

```elixir
@spec list(Miosa.Client.t(), String.t()) :: Miosa.Client.result(list())
```

List all CUA sessions for a computer
(GET `/computers/:computer_id/cua/sessions`).

# `run`

```elixir
@spec run(Miosa.Client.t(), String.t(), String.t(), map()) ::
  Miosa.Client.result(map())
```

Create and start a CUA session for a computer
(POST `/computers/:computer_id/cua/sessions`).

## Options map keys

  * `"model"` — Override the AI model (e.g. `"claude-3-5-sonnet-latest"`).
  * `"max_steps"` — Maximum number of agent steps before stopping.
  * `"tools"` — List of additional tool names to enable.
  * `"timeout"` — Session timeout in seconds.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
