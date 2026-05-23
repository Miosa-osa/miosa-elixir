# `Miosa.SnapshotsStandalone`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/snapshots_standalone.ex#L1)

Fleet-wide snapshot index for admin callers.

Routes live under `/api/v1/admin/snapshots/` and require an admin
credential. Per-computer snapshots remain nested under the computer's
checkpoint resource. This module exposes the fleet-wide read-only index
used by the platform admin dashboard.

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Get a snapshot by ID (GET `/admin/snapshots/:snapshot_id`).

# `list`

```elixir
@spec list(Miosa.Client.t(), map()) :: Miosa.Client.result(list())
```

List all snapshots fleet-wide (GET `/admin/snapshots`).

Accepts optional filter params (e.g. `%{computer_id: "..."}`, `%{status: "ready"}`).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
