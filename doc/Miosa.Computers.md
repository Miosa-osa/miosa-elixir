# `Miosa.Computers`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/computers.ex#L1)

Manage MIOSA computers (VM workspaces).

Computers are the core resource: isolated Linux VMs with a full desktop
environment, terminal access, and an OSA agent running inside each one.

## Example

    client = Miosa.client("msk_u_...")

    {:ok, computer} = Miosa.Computers.create(client, %{
      name: "my-agent-workspace",
      template_type: "miosa-desktop",
      size: "small"
    })

    {:ok, computers} = Miosa.Computers.list(client)
    {:ok, computer} = Miosa.Computers.get(client, computer.id)
    :ok = Miosa.Computers.delete(client, computer.id)

# `create_params`

```elixir
@type create_params() :: %{
  optional(:name) =&gt; String.t(),
  optional(:template_type) =&gt; String.t(),
  optional(:size) =&gt; String.t(),
  optional(:metadata) =&gt; map()
}
```

# `create`

```elixir
@spec create(Miosa.Client.t(), create_params()) ::
  Miosa.Client.result(Miosa.Types.Computer.t())
```

Creates a new computer.

The computer starts in `:creating` status. Use `Miosa.Computer.start/2` to
boot it, or poll `get/2` until the status becomes `:running`.

## Params

  * `:name` — Display name (optional, auto-generated if omitted).
  * `:template_type` — Template to use. Defaults to `"miosa-desktop"`.
  * `:size` — VM size: `"small"` (default), `"medium"`, `"large"`.
  * `:metadata` — Arbitrary key-value map stored with the computer.

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t(), keyword()) ::
  :ok | {:error, Miosa.Error.t()}
```

Deletes a computer and destroys all associated resources.

The computer must be stopped before deletion, or pass `force: true` to
force destroy a running computer (data will be lost).

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t()) ::
  Miosa.Client.result(Miosa.Types.Computer.t())
```

Fetches a single computer by ID.

# `list`

```elixir
@spec list(Miosa.Client.t()) :: Miosa.Client.result([Miosa.Types.Computer.t()])
```

Lists all computers for the authenticated tenant.

Returns a list of `Miosa.Types.Computer` structs ordered by creation time
(newest first).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
