# `Miosa.Types.Workspace`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/types.ex#L297)

Represents a MIOSA workspace — a named group of computers.

# `t`

```elixir
@type t() :: %Miosa.Types.Workspace{
  created_at: String.t() | nil,
  id: String.t(),
  metadata: map() | nil,
  name: String.t(),
  updated_at: String.t() | nil
}
```

# `from_map`

```elixir
@spec from_map(map()) :: t()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
