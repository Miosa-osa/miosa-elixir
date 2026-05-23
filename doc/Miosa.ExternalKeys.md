# `Miosa.ExternalKeys`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/external_keys.ex#L1)

External BYOK keys — Anthropic, OpenAI, Google, Groq, and similar.

Keys are stored encrypted per-user and consumed by dashboard features
(Builder, Optimal, etc.). The backend indexes external keys by `provider`,
not by a surrogate ID.

## Example

    client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

    {:ok, _} = Miosa.ExternalKeys.create(client, "anthropic", "sk-ant-...")
    {:ok, keys} = Miosa.ExternalKeys.list(client)

# `create`

```elixir
@spec create(Miosa.Client.t(), String.t(), String.t(), map()) ::
  Miosa.Client.result(map())
```

Register an external provider key.

`provider` — e.g. `"anthropic"`, `"openai"`, `"google"`, `"groq"`.
`key` — the raw secret key string.
`attrs` — optional additional fields accepted by the API.

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Delete the stored key for a provider.

# `list`

```elixir
@spec list(Miosa.Client.t()) :: Miosa.Client.result(map())
```

List all configured external provider keys.

# `resolve`

```elixir
@spec resolve(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Resolve (preview) the stored key for a provider.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
