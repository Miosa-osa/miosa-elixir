# `Miosa.Types.ServiceLogEvent`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/types.ex#L428)

A single log line emitted by a background service.

# `t`

```elixir
@type t() :: %Miosa.Types.ServiceLogEvent{
  line: String.t(),
  service_id: String.t() | nil,
  stream: String.t() | nil,
  timestamp: String.t() | nil
}
```

# `from_map`

```elixir
@spec from_map(map()) :: t()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
