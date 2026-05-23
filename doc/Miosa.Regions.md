# `Miosa.Regions`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/regions.ex#L1)

Datacenter regions, compute sizes, pricing, and community templates — read-only catalog.

## Example

    client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

    {:ok, regions} = Miosa.Regions.list_regions(client)
    {:ok, sizes} = Miosa.Regions.list_sizes(client)

# `get_template`

```elixir
@spec get_template(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Get a single community template by ID.

# `list_regions`

```elixir
@spec list_regions(Miosa.Client.t()) :: Miosa.Client.result(map())
```

List available datacenter regions.

# `list_sizes`

```elixir
@spec list_sizes(Miosa.Client.t()) :: Miosa.Client.result(map())
```

List available compute sizes.

# `list_templates`

```elixir
@spec list_templates(Miosa.Client.t()) :: Miosa.Client.result(map())
```

List community computer templates.

# `pricing`

```elixir
@spec pricing(Miosa.Client.t()) :: Miosa.Client.result(map())
```

Get static compute pricing data.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
