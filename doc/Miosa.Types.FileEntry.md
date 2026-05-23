# `Miosa.Types.FileEntry`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/types.ex#L145)

A file or directory entry in a computer's filesystem.

# `file_type`

```elixir
@type file_type() :: :file | :directory | :symlink
```

# `t`

```elixir
@type t() :: %Miosa.Types.FileEntry{
  modified_at: String.t() | nil,
  name: String.t(),
  path: String.t(),
  permissions: String.t() | nil,
  size: integer() | nil,
  type: file_type()
}
```

# `from_map`

```elixir
@spec from_map(map()) :: t()
```

---

*Consult [api-reference.md](api-reference.md) for complete listing*
