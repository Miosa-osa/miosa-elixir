# `Miosa.Computer.Env`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/computer/env.ex#L1)

Encrypted env-var CRUD scoped to one computer.

  * `GET    /computers/:id/env`          — list/2
  * `POST   /computers/:id/env`          — set/4
  * `PATCH  /computers/:id/env/:name`    — update/4
  * `DELETE /computers/:id/env/:name`    — delete/3
  * `bulk_set/3` — convenience wrapper over set/4

# `bulk_set`

```elixir
@spec bulk_set(Miosa.Client.t(), String.t(), %{required(String.t()) =&gt; String.t()}) ::
  {:ok, list()} | {:error, Miosa.Error.t()}
```

Convenience: create one env var per entry in `env` map.

Falls back to N individual `set/4` calls (no bulk backend endpoint yet).
Returns a list of results in the same order as `Map.to_list(env)`.

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t(), String.t()) ::
  :ok | {:error, Miosa.Error.t()}
```

Delete an env var by name (DELETE `/computers/:computer_id/env/:name`).

# `list`

```elixir
@spec list(Miosa.Client.t(), String.t()) :: Miosa.Client.result(list())
```

List all env vars for a computer (GET `/computers/:computer_id/env`).

Values may be masked depending on server policy.

# `set`

```elixir
@spec set(Miosa.Client.t(), String.t(), String.t(), String.t()) ::
  Miosa.Client.result(map())
```

Create a new env var (POST `/computers/:computer_id/env`).

Use `update/4` to change an existing one.

# `update`

```elixir
@spec update(Miosa.Client.t(), String.t(), String.t(), String.t()) ::
  Miosa.Client.result(map())
```

Patch the value of an existing env var (PATCH `/computers/:computer_id/env/:name`).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
