# `Miosa.Types.ComputerEvent`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/types.ex#L645)

A real-time lifecycle event emitted by a MIOSA computer.

# `event_type`

```elixir
@type event_type() ::
  :status_changed | :started | :stopped | :error | :checkpoint_created | :raw
```

# `t`

```elixir
@type t() :: %Miosa.Types.ComputerEvent{
  computer_id: String.t() | nil,
  data: map() | String.t() | nil,
  timestamp: String.t() | nil,
  type: event_type()
}
```

# `from_sse`

```elixir
@spec from_sse(String.t(), String.t()) :: t()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
