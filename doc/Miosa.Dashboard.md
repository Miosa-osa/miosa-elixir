# `Miosa.Dashboard`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/dashboard.ex#L1)

Dashboard — aggregated platform overview, polled on login.

## Example

    client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

    {:ok, summary} = Miosa.Dashboard.summary(client)

# `overview`

```elixir
@spec overview(Miosa.Client.t()) :: Miosa.Client.result(map())
```

Get the platform status and health overview (public endpoint).

# `summary`

```elixir
@spec summary(Miosa.Client.t()) :: Miosa.Client.result(map())
```

Get the aggregated user dashboard payload.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
