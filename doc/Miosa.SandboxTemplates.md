# `Miosa.SandboxTemplates`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/sandbox_templates.ex#L1)

Sandbox template management — define reusable base images for sandboxes.

Templates are built from a `build_spec` (a declarative definition of the
base image). Use `build_spec_schema/1` to discover the schema, `validate/2`
to check a spec before creating a template, and `create_build/2` to trigger
a build.

Mutating calls (create, create_build) send an `Idempotency-Key` header
automatically.

## Example

    client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

    {:ok, schema} = Miosa.SandboxTemplates.build_spec_schema(client)

    {:ok, tmpl} = Miosa.SandboxTemplates.create(client, %{
      name: "node-20-base",
      build_spec: %{runtime: "node", version: "20", packages: ["curl"]}
    })

    {:ok, build} = Miosa.SandboxTemplates.create_build(client, tmpl["id"], %{})

# `build_spec_schema`

```elixir
@spec build_spec_schema(Miosa.Client.t()) :: Miosa.Client.result(map())
```

Get the JSON schema for sandbox build specs.

# `create`

```elixir
@spec create(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Create a sandbox template.

Required: `:name`, `:build_spec` (map). Optional: `:description`, `:metadata`,
`:idempotency_key`.

# `create_build`

```elixir
@spec create_build(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Trigger a new build for a sandbox template.

Optional `attrs` may include build-time overrides. Pass `:idempotency_key`
to supply your own idempotency key.

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Fetch a sandbox template by ID.

# `list`

```elixir
@spec list(Miosa.Client.t(), keyword() | map()) :: Miosa.Client.result(map())
```

List sandbox templates for the authenticated tenant.

Options:
  * `:include_aliases` — Include template alias names. Defaults to `false`.

# `list_builds`

```elixir
@spec list_builds(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

List builds for a sandbox template.

# `validate`

```elixir
@spec validate(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Validate a build spec without creating a template.

Returns validation errors or `{:ok, result}` with the normalized spec.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
