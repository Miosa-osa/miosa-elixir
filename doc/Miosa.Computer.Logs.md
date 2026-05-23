# `Miosa.Computer.Logs`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/computer/logs.ex#L1)

Read and stream VM logs for a computer.

  * `GET /computers/:id/logs`         — snapshot (JSON)
  * `GET /computers/:id/logs/stream`  — live SSE stream

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Fetch the most recent log snapshot (GET `/computers/:computer_id/logs`).

## Options

  * `:lines` — Number of log lines to return.
  * `:since` — ISO8601 timestamp; return only lines after this time.

# `stream`

```elixir
@spec stream(Miosa.Client.t(), String.t(), function()) ::
  :ok | {:error, Miosa.Error.t()}
```

Stream live log events via SSE (GET `/computers/:computer_id/logs/stream`).

`callback` is called for each event map `%{type: ..., data: ...}`.
Returns `:ok` when the stream closes or `{:error, reason}` on failure.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
