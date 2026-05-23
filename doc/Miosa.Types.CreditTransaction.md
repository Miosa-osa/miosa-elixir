# `Miosa.Types.CreditTransaction`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/types.ex#L732)

A single credit debit or credit event.

# `t`

```elixir
@type t() :: %Miosa.Types.CreditTransaction{
  amount: integer(),
  created_at: String.t() | nil,
  description: String.t() | nil,
  id: String.t(),
  type: String.t()
}
```

# `from_map`

```elixir
@spec from_map(map()) :: t()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
