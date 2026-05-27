# `Miosa.Volumes`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/volumes.ex#L1)

Persistent block storage volumes that survive instance restarts.

Volumes can be attached to computers to provide durable storage
beyond the ephemeral rootfs.

## Example

    client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

    {:ok, vol} = Miosa.Volumes.create(client, %{name: "data", size_gb: 20})
    {:ok, vol} = Miosa.Volumes.get(client, vol["id"])

# `create`

```elixir
@spec create(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Create a volume.

Required: `:name`, `:size_gb`. Optional: `:region`, and any other attrs.
Pass `:idempotency_key` to supply your own idempotency key.

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Delete a volume by ID.

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Fetch a volume by ID.

# `list`

```elixir
@spec list(Miosa.Client.t(), keyword() | map()) :: Miosa.Client.result(map())
```

List volumes for the authenticated tenant.

Accepts optional filters as a keyword list or map (e.g. `:limit`, `:cursor`).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
