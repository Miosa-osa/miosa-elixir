# `Miosa.Completions`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/completions.ex#L1)

OpenAI-compatible chat and text completion endpoints.

Routes live under `/api/v1/intelligence/` and require an `mki_*`
intelligence key. Streaming endpoints call `callback` for each SSE event.

# `chat`

```elixir
@spec chat(Miosa.Client.t(), String.t(), list(), map(), function() | nil) ::
  Miosa.Client.result(map()) | :ok | {:error, Miosa.Error.t()}
```

Create a chat completion (POST `/intelligence/chat/completions`).

## Parameters

  * `model` — Model ID string.
  * `messages` — List of message maps (`%{"role" => ..., "content" => ...}`).
  * `opts` — Optional extra body params (`:temperature`, `:max_tokens`, etc.).
  * `callback` — Required when `opts.stream == true`. Called with each SSE event map.

When `:stream` is `false` (default), returns `{:ok, response_map}`.

# `create`

```elixir
@spec create(Miosa.Client.t(), String.t(), map(), function() | nil) ::
  Miosa.Client.result(map()) | :ok | {:error, Miosa.Error.t()}
```

Create a text completion (POST `/intelligence/completions`).

## Options

  * `:stream` — When `true`, streams SSE events via `callback`. Defaults to `false`.
  * `:prompt` — Text prompt (string or list of strings).
  * Any extra key is forwarded to the API body.

When `:stream` is `false`, returns `{:ok, response_map}`.
When `:stream` is `true`, pass a `callback` function; returns `:ok` or `{:error, reason}`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
