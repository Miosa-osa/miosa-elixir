# `Miosa.OpenComputers.Fs`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/open_computers.ex#L152)

Remote file system operations on registered hosts.

# `result`

```elixir
@type result() :: {:ok, map()} | {:error, Miosa.Error.t()}
```

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t(), String.t()) :: result()
```

Delete a file or directory on the host.

# `download`

```elixir
@spec download(Miosa.Client.t(), String.t(), String.t()) ::
  {:ok, binary()} | {:error, Miosa.Error.t()}
```

Download a file as binary.

# `list`

```elixir
@spec list(Miosa.Client.t(), String.t(), String.t()) :: result()
```

List directory entries at `remote_path`.

# `mkdir`

```elixir
@spec mkdir(Miosa.Client.t(), String.t(), String.t()) :: result()
```

Create a directory (and all parents) on the host.

# `stat`

```elixir
@spec stat(Miosa.Client.t(), String.t(), String.t()) :: result()
```

Stat a path (size, mode, is_dir, symlink, etc.).

# `upload`

```elixir
@spec upload(Miosa.Client.t(), String.t(), String.t(), binary(), String.t()) ::
  result()
```

Upload `content` (binary) to `remote_path` on the host.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
