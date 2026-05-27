# `Miosa.OpenComputers.Clusters`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/open_computers.ex#L349)

Inference cluster management.

A cluster groups multiple registered hosts to serve an LLM model via an
OpenAI-compatible endpoint at `/inference/{slug}/v1/chat/completions`.

# `result`

```elixir
@type result() :: {:ok, map()} | {:error, Miosa.Error.t()}
```

# `create`

```elixir
@spec create(Miosa.Client.t(), map()) :: result()
```

Create an inference cluster.

`attrs` must include `:name`, `:model`, `:host_ids`.

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t()) :: result()
```

Delete a cluster.

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t()) :: result()
```

Get a specific cluster.

# `list`

```elixir
@spec list(Miosa.Client.t()) :: result()
```

List inference clusters.

# `start`

```elixir
@spec start(Miosa.Client.t(), String.t()) :: result()
```

Start a stopped cluster.

# `stop`

```elixir
@spec stop(Miosa.Client.t(), String.t()) :: result()
```

Stop a running cluster.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
