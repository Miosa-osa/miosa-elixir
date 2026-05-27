# `Miosa.CommandCenter`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/command_center.ex#L1)

Read-only views of the Optimal AI agent fleet.

Routes live under `/api/v1/command-center/` and require a JWT or
`msk_u_*` API key.

# `agents`

```elixir
@spec agents(Miosa.Client.t()) :: Miosa.Client.result(list())
```

List all agents in the fleet (GET `/command-center/agents`).

# `events`

```elixir
@spec events(Miosa.Client.t(), function()) :: :ok | {:error, Miosa.Error.t()}
```

Stream live command-center events via SSE (GET `/command-center/events`).

`callback` is invoked for each event map with keys `type` and `data`.
Returns `:ok` when the stream closes or `{:error, reason}` on failure.

# `metrics`

```elixir
@spec metrics(Miosa.Client.t()) :: Miosa.Client.result(map())
```

Get fleet-wide metrics snapshot (GET `/command-center/metrics`).

# `overview`

```elixir
@spec overview(Miosa.Client.t()) :: Miosa.Client.result(map())
```

Top-level fleet snapshot (GET `/command-center`).

# `presets`

```elixir
@spec presets(Miosa.Client.t()) :: Miosa.Client.result(list())
```

List agent execution presets (GET `/command-center/presets`).

# `running_agents`

```elixir
@spec running_agents(Miosa.Client.t()) :: Miosa.Client.result(list())
```

List currently running agents (GET `/command-center/agents/running`).

# `tiers`

```elixir
@spec tiers(Miosa.Client.t()) :: Miosa.Client.result(map())
```

Get agent tier configuration (GET `/command-center/tiers`).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
