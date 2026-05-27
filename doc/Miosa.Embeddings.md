# `Miosa.Embeddings`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/embeddings.ex#L1)

OpenAI-compatible embedding vectors.

Routes live under `/api/v1/intelligence/embeddings` and require an
`mki_*` intelligence key.

# `create`

```elixir
@spec create(Miosa.Client.t(), String.t() | list(), String.t(), map()) ::
  Miosa.Client.result(map())
```

Create one or more embedding vectors (POST `/intelligence/embeddings`).

`input` may be a string or list of strings.

Returns the full OpenAI-envelope response `%{"object" => "list", "data" => [...]}`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
