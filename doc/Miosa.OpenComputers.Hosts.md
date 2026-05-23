# `Miosa.OpenComputers.Hosts`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/open_computers.ex#L32)

Host registration and lifecycle.

A **host** is a physical or virtual machine you own that has been registered
with MIOSA by installing the `miosa-host` agent. Once registered, MIOSA can
dispatch jobs, manage files, issue tunnels, and run AI agents on it.

The `host_key` is returned **only on creation** — save it immediately.

# `result`

```elixir
@type result() :: {:ok, map()} | {:error, Miosa.Error.t()}
```

# `create`

```elixir
@spec create(Miosa.Client.t(), map()) :: result()
```

Register a new host.

`attrs` must include `:name`. Optional: `:region`, `:labels`.

The returned map includes `host_key` — shown **once**, store it securely.

# `events`

```elixir
@spec events(Miosa.Client.t(), String.t(), function()) ::
  :ok | {:error, Miosa.Error.t()}
```

Stream live host events (SSE).

The `callback` is called for each `%{type: type, data: data}` event map.
Blocks until the stream ends. Returns `:ok` or `{:error, reason}`.

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t()) :: result()
```

Get a host by ID.

# `list`

```elixir
@spec list(
  Miosa.Client.t(),
  keyword()
) :: result()
```

List all registered hosts.

Options: `:page`, `:per_page`.

# `revoke`

```elixir
@spec revoke(Miosa.Client.t(), String.t()) :: result()
```

Revoke a host registration. The host loses access immediately.

# `update`

```elixir
@spec update(Miosa.Client.t(), String.t(), map()) :: result()
```

Update host metadata (name, labels).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
