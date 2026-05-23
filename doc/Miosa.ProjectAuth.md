# `Miosa.ProjectAuth`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/project_auth.ex#L1)

Project Auth — built-in authentication for generated apps inside
sandboxes and deployments.

## Example

    client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

    {:ok, status} = Miosa.ProjectAuth.status(client)
    {:ok, _} = Miosa.ProjectAuth.enable(client, %{provider: "email"})

# `disable`

```elixir
@spec disable(Miosa.Client.t()) :: Miosa.Client.result(map())
```

Disable project auth.

# `enable`

```elixir
@spec enable(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Enable project auth.

Pass an optional config map (e.g. `%{provider: "email"}`).

# `status`

```elixir
@spec status(Miosa.Client.t()) :: Miosa.Client.result(map())
```

Get the current project-auth status and configuration.

# `update`

```elixir
@spec update(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Update project-auth configuration.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
