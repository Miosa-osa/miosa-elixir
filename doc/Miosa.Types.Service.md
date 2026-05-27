# `Miosa.Types.Service`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/types.ex#L369)

Represents a managed background service running inside a computer.

# `status`

```elixir
@type status() :: :stopped | :starting | :running | :stopping | :error
```

# `t`

```elixir
@type t() :: %Miosa.Types.Service{
  auto_restart: boolean() | nil,
  command: String.t() | nil,
  computer_id: String.t(),
  created_at: String.t() | nil,
  env: map() | nil,
  id: String.t(),
  name: String.t(),
  pid: integer() | nil,
  status: status(),
  updated_at: String.t() | nil,
  working_dir: String.t() | nil
}
```

# `from_map`

```elixir
@spec from_map(map()) :: t()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
