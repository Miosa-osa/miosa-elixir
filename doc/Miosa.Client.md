# `Miosa.Client`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/client.ex#L1)

HTTP transport layer for the MIOSA API.

Holds configuration and wraps `Req` for all request types: JSON API calls,
multipart file uploads, binary downloads, and SSE streaming.

Construct a client via `Miosa.client/2` rather than using this module directly.

## Options

  * `:api_key` — Required. API key starting with `msk_`.
  * `:base_url` — Override the API base URL. Defaults to `https://api.miosa.ai/api/v1`.
  * `:timeout` — Request timeout in milliseconds. Defaults to `30_000`.
  * `:receive_timeout` — Receive timeout for long-running requests. Defaults to `60_000`.
  * `:retry` — Whether to retry failed requests. Defaults to `false`.

# `result`

```elixir
@type result(type) :: {:ok, type} | {:error, Miosa.Error.t()}
```

# `t`

```elixir
@type t() :: %Miosa.Client{
  _req: Req.Request.t(),
  api_key: String.t(),
  base_url: String.t(),
  receive_timeout: pos_integer(),
  retry: boolean(),
  timeout: pos_integer()
}
```

# `delete`

```elixir
@spec delete(t(), String.t(), keyword()) :: result(map())
```

Performs a DELETE request and decodes the JSON response.

# `get`

```elixir
@spec get(t(), String.t(), keyword()) :: result(map())
```

Performs a GET request and decodes the JSON response.

# `get_binary`

```elixir
@spec get_binary(t(), String.t(), keyword()) :: result(binary())
```

Performs a GET request and returns the raw binary response body.

Used for downloading files and screenshots.

# `new`

```elixir
@spec new(
  String.t(),
  keyword()
) :: t()
```

Builds a new `Miosa.Client` struct.

Validates the API key format and constructs a base `Req` request with
default headers and options pre-applied.

# `patch`

```elixir
@spec patch(t(), String.t(), map() | nil, keyword()) :: result(map())
```

Performs a PATCH request with a JSON body and decodes the response.

# `post`

```elixir
@spec post(t(), String.t(), map() | nil, keyword()) :: result(map())
```

Performs a POST request with a JSON body and decodes the response.

# `post_multipart`

```elixir
@spec post_multipart(t(), String.t(), list(), keyword()) :: result(map())
```

Performs a multipart POST for file uploads.

`parts` should be a list of `{name, value}` tuples or `{name, value, opts}` tuples
compatible with `Req`'s `:form_multipart` option.

# `put`

```elixir
@spec put(t(), String.t(), map() | nil, keyword()) :: result(map())
```

Performs a PUT request with a JSON body and decodes the response.

# `stream_sse`

```elixir
@spec stream_sse(t(), String.t(), function(), keyword()) ::
  :ok | {:error, Miosa.Error.t()}
```

Opens an SSE stream and calls `callback` for each parsed event.

The callback receives `{event_type :: String.t(), data :: String.t()}` tuples.
The stream is consumed until the connection closes or the server sends `data: [DONE]`.

Returns `:ok` when the stream completes or `{:error, reason}` on failure.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
