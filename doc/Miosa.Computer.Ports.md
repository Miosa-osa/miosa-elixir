# `Miosa.Computer.Ports`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/computer/ports.ex#L1)

Per-port visibility control for a computer.

  * `GET    /computers/:id/ports`          — list/2
  * `POST   /computers/:id/ports`          — create/3
  * `PATCH  /computers/:id/ports/:port`    — update/4
  * `DELETE /computers/:id/ports/:port`    — delete/3

The backend does not expose a single-port GET; `get/3` filters
the list response client-side.

# `create`

```elixir
@spec create(Miosa.Client.t(), String.t(), pos_integer(), map()) ::
  Miosa.Client.result(map())
```

Expose a port with the given visibility options
(POST `/computers/:computer_id/ports`).

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t(), pos_integer()) ::
  :ok | {:error, Miosa.Error.t()}
```

Stop exposing a port (DELETE `/computers/:computer_id/ports/:port`).

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t(), pos_integer()) ::
  Miosa.Client.result(map() | nil)
```

Return the port record for `port`, or `{:ok, nil}` if not exposed.

Filters `list/2` client-side.

# `list`

```elixir
@spec list(Miosa.Client.t(), String.t()) :: Miosa.Client.result(list())
```

List all exposed ports (GET `/computers/:computer_id/ports`).

# `update`

```elixir
@spec update(Miosa.Client.t(), String.t(), pos_integer(), map()) ::
  Miosa.Client.result(map())
```

Patch visibility/auth options for a port
(PATCH `/computers/:computer_id/ports/:port`).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
