# `Miosa.OpenComputers.Jobs`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/open_computers.ex#L100)

Remote job execution on registered hosts.

Jobs dispatch shell commands to a registered host and return the result once
the command completes.

# `result`

```elixir
@type result() :: {:ok, map()} | {:error, Miosa.Error.t()}
```

# `cancel`

```elixir
@spec cancel(Miosa.Client.t(), String.t(), String.t()) :: result()
```

Cancel a running job.

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t(), String.t()) :: result()
```

Get a specific job by ID.

# `list`

```elixir
@spec list(Miosa.Client.t(), String.t(), keyword()) :: result()
```

List jobs for a host.

# `run`

```elixir
@spec run(Miosa.Client.t(), String.t(), map()) :: result()
```

Run a command on a host and return the completed job.

`attrs` must include `:command`. Optional: `:args`, `:env`, `:cwd`, `:timeout`.

# `stream`

```elixir
@spec stream(Miosa.Client.t(), String.t(), String.t(), function()) ::
  :ok | {:error, Miosa.Error.t()}
```

Stream live output events from a running job (SSE).

The callback receives `%{type: type, data: data}` maps. Blocks until done.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
