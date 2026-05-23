# `Miosa.Types.NetworkPolicy`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/types.ex#L544)

The full network policy for a computer, expressed as an ordered list of rules.

# `t`

```elixir
@type t() :: %Miosa.Types.NetworkPolicy{
  computer_id: String.t(),
  rules: [Miosa.Types.NetworkPolicyRule.t()],
  updated_at: String.t() | nil
}
```

# `from_map`

```elixir
@spec from_map(map()) :: t()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
