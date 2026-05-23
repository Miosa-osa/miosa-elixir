# `Miosa.Deployments`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/deployments.ex#L1)

Deployments — sandbox → production publishing surface.

Backend phase status (2026-05-15):
  * `list/2`, `get/2`, `list_builds/2`, `get_build/3`, env helpers: pre-existing
    repo flow.
  * `publish/3`, `versions.*`, `rollback/3`, `domains.*`: Phase 2B/3 target —
    returns the steady-state shape once the publish pipeline lands.
  * `publish_from_sandbox/3`: backward-compatible bridge, works today.

All mutating calls send an `Idempotency-Key` header. Provide your own via
the `:idempotency_key` option or one is generated automatically.

## Example

    client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

    {:ok, sandbox} = Miosa.Sandboxes.create(client, %{
      name: "smile-dental",
      external_workspace_id: "dental-office-123",
      external_user_id: "dr-smith-456"
    })

    # ... agent writes files, runs dev server ...

    {:ok, result} = Miosa.Deployments.publish_from_sandbox(client, sandbox.id, %{
      kind: "static",
      environment: "production",
      external_workspace_id: "dental-office-123"
    })

# `add_domain`

```elixir
@spec add_domain(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Attach a custom domain to a deployment. Returns DNS instructions.

Required: `:domain`. Optional: `:redirect_policy`, attribution,
`:idempotency_key`.

# `create`

```elixir
@spec create(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Create a deployment.

Accepts the documented Phase 2B/3 fields:

  * `:name` (required)
  * `:project_id` — if set, posts to `/projects/:id/deployments`
  * `:source_type`, `:repo_url`, `:branch`
  * `:build_command`, `:run_command`, `:auto_deploy`, `:metadata`
  * `:external_workspace_id`, `:external_user_id`, `:external_project_id`
  * `:idempotency_key`

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Delete a deployment.

# `delete_domain`

```elixir
@spec delete_domain(Miosa.Client.t(), String.t(), String.t()) ::
  Miosa.Client.result(map())
```

Detach a custom domain.

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Fetch a deployment by ID.

# `get_build`

```elixir
@spec get_build(Miosa.Client.t(), String.t(), String.t()) ::
  Miosa.Client.result(map())
```

Get a specific build.

# `get_version`

```elixir
@spec get_version(Miosa.Client.t(), String.t(), String.t()) ::
  Miosa.Client.result(map())
```

Get a specific version.

# `list`

```elixir
@spec list(Miosa.Client.t(), keyword() | map()) :: Miosa.Client.result(map())
```

List deployments for the authenticated tenant.

Accepts filters:

  * `:project_id`, `:state`, `:limit`, `:cursor`
  * `:external_workspace_id`, `:external_user_id`, `:external_project_id`

# `list_builds`

```elixir
@spec list_builds(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

List builds for a deployment (legacy repo flow).

# `list_domains`

```elixir
@spec list_domains(Miosa.Client.t(), String.t(), keyword() | map()) ::
  Miosa.Client.result(map())
```

List custom domains attached to a deployment.

# `list_env`

```elixir
@spec list_env(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

List env vars for a deployment.

# `list_versions`

```elixir
@spec list_versions(Miosa.Client.t(), String.t(), keyword() | map()) ::
  Miosa.Client.result(map())
```

List versions for a deployment. Same attribution filters as `list/2`.

# `promote_version`

```elixir
@spec promote_version(Miosa.Client.t(), String.t(), String.t(), keyword()) ::
  Miosa.Client.result(map())
```

Promote a specific version to active. Optional `:environment`.

Different from `publish/3`: promote points an existing ready version at
the active slot, no rebuild.

# `publish`

```elixir
@spec publish(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Publish a sandbox to a deployment. Phase 2B/3 endpoint.

Required: `:source_sandbox_id`. Optional fields mirror the API contract
(`:kind`, `:environment`, `:output_path`, `:build_command`, `:run_command`,
`:port`, `:health_check_path`, `:data_services`, attribution).

# `publish_from_sandbox`

```elixir
@spec publish_from_sandbox(Miosa.Client.t(), String.t(), map()) ::
  Miosa.Client.result(map())
```

Publish through the backward-compatible bridge `/sandboxes/:id/deploy`.
Works today. Prefer `publish/3` once the release pipeline lands.

# `rollback`

```elixir
@spec rollback(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Roll back a deployment to an older ready version.

If `:version_id` is omitted, the server defaults to the immediately
previous version.

# `set_env`

```elixir
@spec set_env(Miosa.Client.t(), String.t(), map(), keyword()) ::
  Miosa.Client.result(map())
```

Set env vars on a deployment.

Pass `vars` as a map. Optional `:environment` selects which environment.

# `update`

```elixir
@spec update(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Patch a deployment.

# `verify_domain`

```elixir
@spec verify_domain(Miosa.Client.t(), String.t(), String.t()) ::
  Miosa.Client.result(map())
```

Trigger DNS + TLS verification on a pending domain.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
