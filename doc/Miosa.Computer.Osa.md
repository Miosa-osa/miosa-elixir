# `Miosa.Computer.Osa`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/computer/osa.ex#L1)

Task dispatch to the in-VM OSA agent.

Wraps:
  * `POST   /computers/:id/osa/task`      — submit_task/3
  * `DELETE /computers/:id/osa/task`      — cancel_task/2
  * `GET    /computers/:id/osa/status`    — status/2
  * `POST   /computers/:id/osa/configure` — configure/3

# `cancel_task`

```elixir
@spec cancel_task(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Cancel the currently-running OSA task, if any
(DELETE `/computers/:computer_id/osa/task`).

# `configure`

```elixir
@spec configure(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Update OSA runtime configuration — model, tools, secrets, etc.
(POST `/computers/:computer_id/osa/configure`).

# `status`

```elixir
@spec status(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Return OSA's current task, configuration, and health snapshot
(GET `/computers/:computer_id/osa/status`).

# `submit_task`

```elixir
@spec submit_task(Miosa.Client.t(), String.t(), String.t(), map()) ::
  Miosa.Client.result(map())
```

Submit a free-form task to the in-VM OSA agent
(POST `/computers/:computer_id/osa/task`).

Additional params are merged into the request body.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
