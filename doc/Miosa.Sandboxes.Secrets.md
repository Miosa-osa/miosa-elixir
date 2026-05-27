# `Miosa.Sandboxes.Secrets`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.1.0/lib/miosa/sandboxes/secrets.ex#L1)

Sandbox-bound view of `Miosa.Secrets`.

Every call pre-populates `resource_id` with the sandbox's ID and sets
`resource_type` to `"sandbox"`. This means you never have to repeat the
sandbox ID in each call.

## Usage

    {:ok, sandbox} = Miosa.Sandboxes.create(client, %{name: "my-box"})

    # Bind a secret to this sandbox
    {:ok, secret} = Miosa.Sandboxes.Secrets.set(sandbox, client, %{
      name: "OPENAI_KEY",
      value: "sk-...",
      expose_as_env: "OPENAI_API_KEY"
    })

    {:ok, secrets} = Miosa.Sandboxes.Secrets.list(sandbox, client)
    {:ok, flow}    = Miosa.Sandboxes.Secrets.connect(sandbox, client, "github")

The `sandbox` argument may be either a `Miosa.Types.Computer.t()` struct or
a plain binary sandbox ID string.

# `connect`

```elixir
@spec connect(map() | String.t(), Miosa.Client.t(), String.t(), map()) ::
  Miosa.Client.result(Miosa.OauthFlow.t())
```

Start an OAuth Connect flow scoped to this sandbox.

# `delete`

```elixir
@spec delete(map() | String.t(), Miosa.Client.t(), String.t()) ::
  :ok | {:error, Miosa.Error.t()}
```

Delete a secret by ID.

# `get`

```elixir
@spec get(map() | String.t(), Miosa.Client.t(), String.t()) ::
  Miosa.Client.result(map())
```

Fetch a single secret by ID.

# `list`

```elixir
@spec list(map() | String.t(), Miosa.Client.t(), map()) ::
  Miosa.Client.result([map()])
```

List secrets scoped to this sandbox.

# `list_bindings`

```elixir
@spec list_bindings(map() | String.t(), Miosa.Client.t(), map()) ::
  Miosa.Client.result([map()])
```

List bindings scoped to this sandbox.

# `rotate`

```elixir
@spec rotate(map() | String.t(), Miosa.Client.t(), String.t(), map()) ::
  Miosa.Client.result(map())
```

Rotate a secret's value.

# `set`

```elixir
@spec set(map() | String.t(), Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Create a secret scoped to this sandbox.

Merges `resource_id` and `resource_type="sandbox"` into `attrs` unless
already present.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
