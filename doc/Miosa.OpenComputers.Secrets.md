# `Miosa.OpenComputers.Secrets`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/open_computers.ex#L397)

Encrypted secret management for OpenComputers.

Secrets can be scoped to the whole tenant or to a specific host. The secret
value is encrypted at rest and injected as environment variables on the host.

# `result`

```elixir
@type result() :: {:ok, map()} | {:error, Miosa.Error.t()}
```

# `create`

```elixir
@spec create(Miosa.Client.t(), map()) :: result()
```

Create a tenant-scoped secret.

`attrs` must include `:name` and `:value`. Optional: `:description`.

# `create_for_host`

```elixir
@spec create_for_host(Miosa.Client.t(), String.t(), map()) :: result()
```

Create a secret scoped to a specific host.

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t()) :: result()
```

Delete a tenant-scoped secret.

# `delete_for_host`

```elixir
@spec delete_for_host(Miosa.Client.t(), String.t(), String.t()) :: result()
```

Delete a host-scoped secret.

# `list`

```elixir
@spec list(Miosa.Client.t()) :: result()
```

List tenant-scoped secrets.

# `list_for_host`

```elixir
@spec list_for_host(Miosa.Client.t(), String.t()) :: result()
```

List secrets scoped to a specific host.

# `update`

```elixir
@spec update(Miosa.Client.t(), String.t(), map()) :: result()
```

Update a tenant-scoped secret.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
