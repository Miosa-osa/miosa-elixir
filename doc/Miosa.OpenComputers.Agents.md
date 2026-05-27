# `Miosa.OpenComputers.Agents`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/open_computers.ex#L294)

AI agent dispatch for registered hosts.

Dispatch an AI agent to autonomously complete a task on your host. The agent
can run commands, edit files, browse the web, and more.

# `result`

```elixir
@type result() :: {:ok, map()} | {:error, Miosa.Error.t()}
```

# `cancel`

```elixir
@spec cancel(Miosa.Client.t(), String.t(), String.t()) :: result()
```

Cancel a running agent session.

# `dispatch`

```elixir
@spec dispatch(Miosa.Client.t(), String.t(), map()) :: result()
```

Dispatch an AI agent to run a task on the host.

`attrs` must include `:task`. Optional: `:model_id`, `:max_turns`, `:context`.

# `events`

```elixir
@spec events(Miosa.Client.t(), String.t(), String.t(), function()) ::
  :ok | {:error, Miosa.Error.t()}
```

Stream live events from an agent session (SSE).

The callback receives `%{type: type, data: data}` maps. Blocks until done.

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t(), String.t()) :: result()
```

Get a specific agent session.

# `list`

```elixir
@spec list(Miosa.Client.t(), String.t()) :: result()
```

List agent sessions for a host.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
