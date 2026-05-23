# `Miosa.Types.DirEntry`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/types.ex#L611)

A single entry returned by a directory listing.

# `t`

```elixir
@type t() :: %Miosa.Types.DirEntry{
  modified_at: String.t() | nil,
  name: String.t(),
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
