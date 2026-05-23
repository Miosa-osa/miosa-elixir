# `Miosa.Types.Window`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/types.ex#L70)

Represents an open window on the computer desktop.

# `t`

```elixir
@type t() :: %Miosa.Types.Window{
  focused: boolean() | nil,
  height: integer() | nil,
  id: integer(),
  title: String.t(),
  width: integer() | nil,
  x: integer() | nil,
  y: integer() | nil
}
```

# `from_map`

```elixir
@spec from_map(map()) :: t()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
