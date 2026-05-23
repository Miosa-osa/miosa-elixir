# `Miosa.Error`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/error.ex#L1)

Exception raised for MIOSA API errors.

Covers both HTTP-level errors (4xx, 5xx) and client-level errors
(network failures, JSON decode errors, invalid configuration).

## Fields

  * `:message` — Human-readable error description.
  * `:status` — HTTP status code (integer), or `nil` for non-HTTP errors.
  * `:code` — Machine-readable error code string from the API (e.g. `"INSUFFICIENT_CREDITS"`), or `nil`.
  * `:body` — Raw response body map, when available.

## Examples

    iex> raise Miosa.Error, message: "Not found", status: 404, code: "NOT_FOUND"
    ** (Miosa.Error) [404] NOT_FOUND: Not found

# `t`

```elixir
@type t() :: %Miosa.Error{
  __exception__: true,
  body: map() | nil,
  code: String.t() | nil,
  message: String.t(),
  status: pos_integer() | nil
}
```

# `from_exception`

```elixir
@spec from_exception(Exception.t() | term()) :: t()
```

Builds a `Miosa.Error` for non-HTTP failures (network errors, decode errors).

# `from_response`

```elixir
@spec from_response(Req.Response.t()) :: t()
```

Builds a `Miosa.Error` from a `Req.Response` struct.

Parses the JSON body for `"error"` and `"code"` keys following the
MIOSA API error envelope format.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
