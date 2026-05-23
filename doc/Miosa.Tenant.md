# `Miosa.Tenant`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/tenant.ex#L1)

Current tenant info — plan limits and live usage counters.

## Example

    client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

    {:ok, plan} = Miosa.Tenant.current(client)
    IO.inspect(plan["plan"])

# `current`

```elixir
@spec current(Miosa.Client.t()) :: Miosa.Client.result(map())
```

Get the current tenant's plan, limits, and live usage counters.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
