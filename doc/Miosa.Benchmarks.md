# `Miosa.Benchmarks`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/benchmarks.ex#L1)

Admin-triggered platform benchmark runs.

Routes live under `/api/v1/admin/benchmarks/` and require an admin
credential (`msk_a_*` / `msk_p_*` or admin JWT). Available run kinds
include `cold_boot`, `fleet_routing`, `concurrent_create`, and `full_e2e`.

# `cancel`

```elixir
@spec cancel(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Cancel a running benchmark (POST `/admin/benchmarks/:benchmark_id/cancel`).

# `compare`

```elixir
@spec compare(Miosa.Client.t(), String.t(), String.t(), map()) ::
  Miosa.Client.result(map())
```

Compare two benchmark runs (POST `/admin/benchmarks/compare`).

# `create`

```elixir
@spec create(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Start a new benchmark run (POST `/admin/benchmarks`).

Pass `kind:` and run-specific options. E.g.:

    Miosa.Benchmarks.create(client, %{kind: "cold_boot", count: 10})

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Get a benchmark run by ID (GET `/admin/benchmarks/:benchmark_id`).

# `list`

```elixir
@spec list(Miosa.Client.t(), map()) :: Miosa.Client.result(list())
```

List all benchmark runs (GET `/admin/benchmarks`).

Accepts optional filter params (e.g. `%{kind: "cold_boot"}`).

# `samples`

```elixir
@spec samples(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(list())
```

Return per-iteration timing samples for a benchmark run
(GET `/admin/benchmarks/:benchmark_id/samples`).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
