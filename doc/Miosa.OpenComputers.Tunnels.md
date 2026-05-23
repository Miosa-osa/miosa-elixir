# `Miosa.OpenComputers.Tunnels`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/open_computers.ex#L248)

HTTP tunnel management for registered hosts.

Tunnels expose a local port on the host over a MIOSA-managed public URL.

# `result`

```elixir
@type result() :: {:ok, map()} | {:error, Miosa.Error.t()}
```

# `create`

```elixir
@spec create(Miosa.Client.t(), String.t(), map()) :: result()
```

Create an HTTP tunnel exposing a local port on the host.

`attrs` must include `:target_port`. Optional: `:auth_mode`, `:slug`.

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t(), String.t()) :: result()
```

Delete a tunnel.

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t(), String.t()) :: result()
```

Get a specific tunnel.

# `list`

```elixir
@spec list(Miosa.Client.t(), String.t()) :: result()
```

List all tunnels for a host.

# `update`

```elixir
@spec update(Miosa.Client.t(), String.t(), String.t(), map()) :: result()
```

Update a tunnel (port, auth mode, enabled flag).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
