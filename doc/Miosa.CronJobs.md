# `Miosa.CronJobs`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/cron_jobs.ex#L1)

Cron jobs — scheduled work with full CRUD, pause/resume, run-now, and
execution history.

Mutating calls (create, update, pause, resume, run_now) send an
`Idempotency-Key` header automatically.

## Example

    client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

    {:ok, job} = Miosa.CronJobs.create(client, %{
      name: "nightly-report",
      schedule: "0 4 * * *",
      url: "https://api.example.com/reports"
    })

    {:ok, _} = Miosa.CronJobs.run_now(client, job["id"])
    {:ok, history} = Miosa.CronJobs.list_executions(client, job["id"])

# `create`

```elixir
@spec create(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Create a cron job.

Required: `:name`, `:schedule` (cron expression e.g. `"0 4 * * *"`).
Optional: `:url`, `:payload`, `:timezone`, `:enabled`, `:idempotency_key`.

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Delete a cron job by ID.

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Fetch a cron job by ID.

# `get_execution`

```elixir
@spec get_execution(Miosa.Client.t(), String.t(), String.t()) ::
  Miosa.Client.result(map())
```

Get a specific execution record for a cron job.

# `list`

```elixir
@spec list(Miosa.Client.t(), keyword() | map()) :: Miosa.Client.result(map())
```

List cron jobs for the authenticated tenant.

Accepts optional filters as a keyword list or map (e.g. `:limit`, `:cursor`).

# `list_executions`

```elixir
@spec list_executions(Miosa.Client.t(), String.t(), keyword() | map()) ::
  Miosa.Client.result(map())
```

List execution history for a cron job.

# `pause`

```elixir
@spec pause(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Pause a cron job (stops future scheduled runs).

# `resume`

```elixir
@spec resume(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Resume a paused cron job.

# `run_now`

```elixir
@spec run_now(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Trigger an immediate execution of a cron job outside its schedule.

# `update`

```elixir
@spec update(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Update a cron job.

Pass any fields to update; nil values are dropped.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
