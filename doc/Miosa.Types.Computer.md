# `Miosa.Types.Computer`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/types.ex#L13)

Represents a MIOSA computer (VM workspace).

# `status`

```elixir
@type status() ::
  :creating | :starting | :running | :stopping | :stopped | :error | :destroying
```

# `t`

```elixir
@type t() :: %Miosa.Types.Computer{
  created_at: String.t() | nil,
  id: String.t(),
  ip_address: String.t() | nil,
  metadata: map() | nil,
  name: String.t(),
  size: String.t() | nil,
  status: status(),
  template_type: String.t() | nil,
  updated_at: String.t() | nil,
  vnc_url: String.t() | nil
}
```

# `from_map`

```elixir
@spec from_map(map()) :: t()
```

Builds a `Computer` struct from a raw API response map.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
