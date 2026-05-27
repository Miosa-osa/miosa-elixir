# `Miosa.Computer.Metrics`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/computer/metrics.ex#L1)

Time-series RAM/CPU/credit metrics for a computer.

Maps to `GET /computers/:id/metrics`.

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t(), String.t()) :: Miosa.Client.result(map())
```

Return metric series for a time window
(GET `/computers/:computer_id/metrics`).

`window` is a duration string such as `"1h"`, `"24h"`, or `"7d"`.
Defaults to `"1h"`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
