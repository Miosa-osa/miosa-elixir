# `Miosa.Types.NetworkPolicyRule`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/types.ex#L509)

A single network firewall rule (allow or deny).

# `action`

```elixir
@type action() :: :allow | :deny
```

# `direction`

```elixir
@type direction() :: :ingress | :egress
```

# `t`

```elixir
@type t() :: %Miosa.Types.NetworkPolicyRule{
  action: action(),
  direction: direction(),
  host: String.t() | nil,
  port: String.t() | pos_integer() | nil,
  protocol: String.t() | nil
}
```

# `from_map`

```elixir
@spec from_map(map()) :: t()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
