# `Miosa.Types.CustomDomain`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/types.ex#L456)

Represents a custom domain registered for a MIOSA computer.

# `status`

```elixir
@type status() :: :pending | :verifying | :active | :failed
```

# `t`

```elixir
@type t() :: %Miosa.Types.CustomDomain{
  computer_id: String.t() | nil,
  created_at: String.t() | nil,
  dns_instructions: map() | nil,
  domain: String.t(),
  id: String.t(),
  port: pos_integer() | nil,
  status: status(),
  tls: boolean() | nil
}
```

# `from_map`

```elixir
@spec from_map(map()) :: t()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
