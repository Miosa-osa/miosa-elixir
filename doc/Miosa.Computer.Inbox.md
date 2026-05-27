# `Miosa.Computer.Inbox`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/computer/inbox.ex#L1)

Per-computer inbox configuration for Optimal inbound-email routing.

Maps to `GET /computers/:id/inbox` and `PATCH /computers/:id/inbox`.

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Fetch the current inbox configuration (GET `/computers/:computer_id/inbox`).

# `update`

```elixir
@spec update(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Patch one or more inbox fields (PATCH `/computers/:computer_id/inbox`).

Common fields: `alias`, `enabled`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
