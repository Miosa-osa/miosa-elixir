# `Miosa.Types.Snapshot`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/types.ex#L327)

Represents a disk checkpoint (snapshot) of a MIOSA computer.

# `status`

```elixir
@type status() :: :creating | :ready | :failed | :deleting
```

# `t`

```elixir
@type t() :: %Miosa.Types.Snapshot{
  computer_id: String.t(),
  created_at: String.t() | nil,
  description: String.t() | nil,
  id: String.t(),
  name: String.t() | nil,
  size_bytes: integer() | nil,
  status: status()
}
```

# `from_map`

```elixir
@spec from_map(map()) :: t()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
