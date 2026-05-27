# `Miosa.Types.FileStat`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/types.ex#L575)

Detailed stat information for a single filesystem path.

# `t`

```elixir
@type t() :: %Miosa.Types.FileStat{
  created_at: String.t() | nil,
  is_symlink: boolean() | nil,
  mode: String.t() | nil,
  modified_at: String.t() | nil,
  name: String.t() | nil,
  path: String.t(),
  size: integer() | nil,
  type: :file | :directory | :symlink
}
```

# `from_map`

```elixir
@spec from_map(map()) :: t()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
