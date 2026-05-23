# `Miosa.Types.ExecResult`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/types.ex#L117)

Result of a command executed inside a computer.

# `t`

```elixir
@type t() :: %Miosa.Types.ExecResult{
  exit_code: integer(),
  output: String.t() | nil,
  stderr: String.t() | nil,
  stdout: String.t() | nil
}
```

# `from_map`

```elixir
@spec from_map(map()) :: t()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
