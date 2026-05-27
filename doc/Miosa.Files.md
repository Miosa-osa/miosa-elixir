# `Miosa.Files`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/files.ex#L1)

Upload, download, list, and manage files inside a MIOSA computer.

File operations interact with the computer's filesystem via the MIOSA API.
Paths are absolute paths inside the VM (e.g. `"/home/user/myfile.txt"`).

## Example

    # Upload a local file
    :ok = Miosa.Files.upload(client, computer_id, "./local.txt", "/home/user/remote.txt")

    # Download a file
    {:ok, content} = Miosa.Files.download(client, computer_id, "/home/user/remote.txt")
    File.write!("local_copy.txt", content)

    # List directory contents
    {:ok, entries} = Miosa.Files.list(client, computer_id, "/home/user")
    Enum.each(entries, fn e -> IO.puts("#{e.type}: #{e.name}") end)

    # Get a temporary download URL
    {:ok, export} = Miosa.Files.export(client, computer_id, "/home/user/report.pdf")
    IO.puts("Download at: #{export.url}")

    # Delete a file
    :ok = Miosa.Files.delete(client, computer_id, "/home/user/old.txt")

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t(), String.t(), keyword()) ::
  :ok | {:error, Miosa.Error.t()}
```

Deletes a file or directory on the computer.

## Options

  * `:recursive` — Delete directories recursively. Defaults to `false`.

# `download`

```elixir
@spec download(Miosa.Client.t(), String.t(), String.t()) ::
  Miosa.Client.result(binary())
```

Downloads a file from the computer and returns its binary content.

Returns `{:ok, binary()}` where `binary()` is the raw file bytes.

# `download_to`

```elixir
@spec download_to(Miosa.Client.t(), String.t(), String.t(), String.t()) ::
  :ok | {:error, Miosa.Error.t() | File.Error.t()}
```

Downloads a file and writes it to a local path.

Returns `:ok` on success or `{:error, reason}` on failure.
`reason` may be a `Miosa.Error` (API failure) or `File.Error` (filesystem write failure).

# `export`

```elixir
@spec export(Miosa.Client.t(), String.t(), String.t()) ::
  Miosa.Client.result(Miosa.Types.ExportResult.t())
```

Generates a temporary signed download URL for a file on the computer.

The URL is publicly accessible for a limited time (typically 15–60 minutes).
Useful for sharing files without streaming through the API.

Returns `{:ok, Miosa.Types.ExportResult.t()}` with `:url` and `:expires_at`.

# `list`

```elixir
@spec list(Miosa.Client.t(), String.t(), String.t()) ::
  Miosa.Client.result([Miosa.Types.FileEntry.t()])
```

Lists the contents of a directory on the computer.

Returns a list of `Miosa.Types.FileEntry` structs, each with `:name`,
`:path`, `:type` (`:file`, `:directory`, `:symlink`), `:size`, and `:modified_at`.

# `upload`

```elixir
@spec upload(
  Miosa.Client.t(),
  String.t(),
  String.t() | {:binary, binary(), String.t()},
  String.t(),
  keyword()
) :: :ok | {:error, Miosa.Error.t()}
```

Uploads a local file to the computer at the given remote path.

`local_path` can be:
- A filesystem path string (`"./myfile.txt"`)
- A `{:binary, content, filename}` tuple for in-memory content

## Options

  * `:create_dirs` — Create parent directories if they don't exist. Defaults to `true`.

# `write`

```elixir
@spec write(Miosa.Client.t(), String.t(), String.t(), binary()) ::
  :ok | {:error, Miosa.Error.t()}
```

Writes string or binary content directly to a file on the computer.

Convenience wrapper around `upload/5` for in-memory content.

## Example

    :ok = Miosa.Files.write(client, computer_id, "/home/user/hello.txt", "Hello, world!")

---

*Consult [api-reference.md](api-reference.md) for complete listing*
