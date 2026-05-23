# `Miosa.Sandbox.Env`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/sandbox/env.ex#L1)

Per-sandbox env-var reader (GET `/sandboxes/:id/env`).

The backend currently exposes a read-only listing. To set env vars,
pass `env:` at sandbox creation time or via the template build-spec.

# `list`

```elixir
@spec list(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

List env vars for a sandbox (GET `/sandboxes/:sandbox_id/env`).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
