# `Miosa.Workspaces`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/workspaces.ex#L1)

Manage MIOSA workspaces.

A workspace groups one or more computers under a shared project boundary.
Workspaces are identified by an ID and carry a display name and optional
metadata. Every computer belongs to exactly one workspace.

## Example

    client = Miosa.client("msk_u_...")

    {:ok, ws} = Miosa.Workspaces.create(client, %{name: "my-project"})
    {:ok, workspaces} = Miosa.Workspaces.list(client)
    {:ok, ws} = Miosa.Workspaces.get(client, ws.id)
    {:ok, ws} = Miosa.Workspaces.update(client, ws.id, %{name: "renamed"})
    {:ok, computers} = Miosa.Workspaces.list_computers(client, ws.id)
    :ok = Miosa.Workspaces.delete(client, ws.id)

# `create_params`

```elixir
@type create_params() :: %{:name =&gt; String.t(), optional(:metadata) =&gt; map()}
```

# `update_params`

```elixir
@type update_params() :: %{
  optional(:name) =&gt; String.t(),
  optional(:metadata) =&gt; map()
}
```

# `create`

```elixir
@spec create(Miosa.Client.t(), create_params()) ::
  Miosa.Client.result(Miosa.Types.Workspace.t())
```

Creates a new workspace.

## Params

  * `:name` — Required. Display name for the workspace.
  * `:metadata` — Optional. Arbitrary key-value map.

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
```

Deletes a workspace.

All computers in the workspace must be stopped or destroyed before deletion,
or the API will return a 409 conflict.

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t()) ::
  Miosa.Client.result(Miosa.Types.Workspace.t())
```

Fetches a single workspace by ID.

# `list`

```elixir
@spec list(Miosa.Client.t()) :: Miosa.Client.result([Miosa.Types.Workspace.t()])
```

Lists all workspaces for the authenticated tenant.

# `list_computers`

```elixir
@spec list_computers(Miosa.Client.t(), String.t()) ::
  Miosa.Client.result([Miosa.Types.Computer.t()])
```

Lists all computers belonging to a workspace.

# `update`

```elixir
@spec update(Miosa.Client.t(), String.t(), update_params()) ::
  Miosa.Client.result(Miosa.Types.Workspace.t())
```

Updates a workspace's attributes.

Only the supplied fields are updated (PATCH semantics).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
