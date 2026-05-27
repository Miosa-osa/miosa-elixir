# `Miosa.Analytics`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/analytics.ex#L1)

Analytics — admin-scoped overview and timeseries metrics.

Requires an admin (`msk_a_` / `msk_p_`) key.

## Example

    client = Miosa.client(System.fetch_env!("MIOSA_ADMIN_KEY"))

    {:ok, overview} = Miosa.Analytics.overview(client)
    {:ok, ts} = Miosa.Analytics.timeseries(client, %{metric: "computers", period: "7d"})

# `overview`

```elixir
@spec overview(Miosa.Client.t(), keyword() | map()) :: Miosa.Client.result(map())
```

Get the platform analytics overview.

Accepts optional filters as a keyword list or map (e.g. `:period`, `:tenant_id`).

# `timeseries`

```elixir
@spec timeseries(Miosa.Client.t(), keyword() | map()) :: Miosa.Client.result(map())
```

Get a timeseries for a metric over a period.

Common options: `:metric` (e.g. `"computers"`), `:period` (e.g. `"7d"`).
Accepts any additional filters supported by the API.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
