# `Miosa.Sandbox.Files`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.1.0/lib/miosa/sandbox/files.ex#L1)

File-system operations on a sandbox.

Wraps:
  * `GET  /sandboxes/:id/files/tree`       — tree/3
  * `POST /sandboxes/:id/files/write-many` — write_many/3
  * `GET  /sandboxes/:id/files/watch` (SSE) — watch/3

# `tree`

```elixir
@spec tree(Miosa.Client.t(), String.t(), keyword()) :: Miosa.Client.result(map())
```

Return a recursive file tree rooted at `path` up to `depth` levels.

GET `/sandboxes/:sandbox_id/files/tree?path=<path>&depth=<depth>`

Returns `{:ok, tree_node}` where the node has the shape:
`%{"path" => _, "type" => "dir"|"file", "name" => _, "children" => [...]?}`.

# `watch`

```elixir
@spec watch(Miosa.Client.t(), String.t(), keyword()) ::
  {:ok, Enumerable.t()} | {:error, Miosa.Error.t()}
```

Stream file-system events from a sandbox as SSE.

GET `/sandboxes/:sandbox_id/files/watch`

Returns `{:ok, stream}` where `stream` is a `Stream` emitting maps like
`%{"type" => "created"|"modified"|"deleted", "path" => _, "size_bytes" => _}`.

The stream terminates when the connection drops or the caller stops consuming.

# `write_many`

```elixir
@spec write_many(Miosa.Client.t(), String.t(), [map()]) :: Miosa.Client.result(map())
```

Write multiple files in a single request.

POST `/sandboxes/:sandbox_id/files/write-many`

`files` is a list of `%{path: path, content: binary_or_string}`. Content
is base64-encoded automatically.

Returns `{:ok, %{"written" => [...], "failed" => [...]}}`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
