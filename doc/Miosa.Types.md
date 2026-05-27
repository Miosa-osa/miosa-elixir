# `Miosa.Types`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/types.ex#L1)

Typed structs representing all MIOSA API response objects.

All structs use atom keys and provide a `from_map/1` constructor that
accepts the raw string-keyed maps returned by the API.

# `visibility`

```elixir
@type visibility() :: :public | :tenant | :key
```

Controls who can access a computer's HTTP endpoints.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
