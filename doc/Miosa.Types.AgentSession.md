# `Miosa.Types.AgentSession`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/types.ex#L195)

A CUA (Computer-Use Agent) session running on a computer.

# `status`

```elixir
@type status() :: :pending | :running | :completed | :failed | :cancelled
```

# `t`

```elixir
@type t() :: %Miosa.Types.AgentSession{
  computer_id: String.t(),
  created_at: String.t() | nil,
  error: String.t() | nil,
  goal: String.t() | nil,
  id: String.t(),
  result: String.t() | nil,
  status: status(),
  updated_at: String.t() | nil
}
```

# `from_map`

```elixir
@spec from_map(map()) :: t()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
