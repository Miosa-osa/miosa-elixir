# `Miosa.Models`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/models.ex#L1)

List available LLM models routed through the MIOSA intelligence gateway.

Routes live under `/api/v1/intelligence/` and require an `mki_*`
intelligence key or a JWT (dashboard users).

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map() | nil)
```

Get a single model by id, filtering the list response client-side.

Returns `{:ok, model}` or `{:ok, nil}` if not found.

# `list`

```elixir
@spec list(Miosa.Client.t(), map()) :: Miosa.Client.result(list())
```

List all models available to the calling tenant (OpenAI-compatible shape).

Accepts optional filter params (e.g. `provider:`, `type:`).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
