# `Miosa.AuditLog`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/audit_log.ex#L1)

Audit log — admin-scoped event stream.

Requires an admin (`msk_a_` / `msk_p_`) key.

## Example

    client = Miosa.client(System.fetch_env!("MIOSA_ADMIN_KEY"))

    {:ok, events} = Miosa.AuditLog.list(client)
    {:ok, filtered} = Miosa.AuditLog.list(client, %{action: "computer.create", limit: 50})

# `list`

```elixir
@spec list(Miosa.Client.t(), keyword() | map()) :: Miosa.Client.result(map())
```

List audit-log events.

Accepts optional filters as a keyword list or map (e.g. `:action`, `:limit`,
`:cursor`, `:since`).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
