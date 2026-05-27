# `Miosa.Templates`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.1.0/lib/miosa/templates.ex#L1)

Sandbox template catalog.

Wraps `GET /api/v1/sandbox-templates`.

## Example

    client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))
    {:ok, templates} = Miosa.Templates.list(client)
    Enum.each(templates, &IO.inspect(&1["name"]))

# `list`

```elixir
@spec list(Miosa.Client.t()) :: Miosa.Client.result([map()])
```

List available sandbox templates.

Returns a list of template maps with keys:
`"id"`, `"name"`, `"description"`, `"image_id"`, `"categories"`,
`"default_cpu"`, `"default_memory_mb"`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
