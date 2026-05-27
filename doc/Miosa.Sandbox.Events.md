# `Miosa.Sandbox.Events`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/sandbox/events.ex#L1)

SSE event streams for a sandbox.

  * `GET /sandboxes/:id/events`             — stream/3
  * `GET /sandboxes/:id/files/watch?path=…` — watch_dir/4

# `stream`

```elixir
@spec stream(Miosa.Client.t(), String.t(), function()) ::
  :ok | {:error, Miosa.Error.t()}
```

Stream live sandbox events via SSE (GET `/sandboxes/:sandbox_id/events`).

`callback` is called for each event map with keys `type` and `data`.
Returns `:ok` when the stream closes or `{:error, reason}` on failure.

# `watch_dir`

```elixir
@spec watch_dir(Miosa.Client.t(), String.t(), String.t(), function(), keyword()) ::
  :ok | {:error, Miosa.Error.t()}
```

Watch a directory for filesystem changes via SSE
(GET `/sandboxes/:sandbox_id/files/watch?path=…`).

`callback` is called for each event map with keys `type` and `data`.
Returns `:ok` when the stream closes or `{:error, reason}` on failure.

## Options

  * `:recursive` — When `true`, watch the directory tree recursively. Defaults to `false`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
