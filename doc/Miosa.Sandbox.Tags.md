# `Miosa.Sandbox.Tags`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/sandbox/tags.ex#L1)

Tag replacement for a sandbox (PATCH `/sandboxes/:id/tags`).

# `set`

```elixir
@spec set(Miosa.Client.t(), String.t(), [String.t()]) :: Miosa.Client.result(map())
```

Replace the full tag list for a sandbox
(PATCH `/sandboxes/:sandbox_id/tags`).

The entire tag list is replaced — not merged.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
