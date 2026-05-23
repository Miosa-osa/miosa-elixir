# `Miosa.Types.AgentEvent`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/types.ex#L242)

A server-sent event from a running agent session.

# `event_type`

```elixir
@type event_type() ::
  :thinking | :action | :screenshot | :result | :error | :done | :token | :raw
```

# `t`

```elixir
@type t() :: %Miosa.Types.AgentEvent{
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
