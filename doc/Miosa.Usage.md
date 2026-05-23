# `Miosa.Usage`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/usage.ex#L1)

Usage — current period summary, per-session metering, and report queries.

## Example

    client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

    {:ok, summary} = Miosa.Usage.current(client)
    {:ok, sessions} = Miosa.Usage.sessions(client, %{limit: 100})

# `current`

```elixir
@spec current(Miosa.Client.t()) :: Miosa.Client.result(map())
```

Get the current period usage summary.

# `report`

```elixir
@spec report(Miosa.Client.t(), keyword() | map()) :: Miosa.Client.result(map())
```

Get a usage report for a period.

Options: `:period_start` and `:period_end` (ISO 8601 strings), plus any
additional filters accepted by the API.

# `sessions`

```elixir
@spec sessions(Miosa.Client.t(), keyword() | map()) :: Miosa.Client.result(map())
```

List per-session metering events.

Accepts optional filters as a keyword list or map (e.g. `:limit`, `:cursor`,
`:computer_id`).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
