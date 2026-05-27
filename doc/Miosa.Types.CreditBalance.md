# `Miosa.Types.CreditBalance`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/types.ex#L710)

Current credit balance for the authenticated tenant.

# `t`

```elixir
@type t() :: %Miosa.Types.CreditBalance{
  balance: integer(),
  expires_at: String.t() | nil,
  plan: String.t() | nil
}
```

# `from_map`

```elixir
@spec from_map(map()) :: t()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
