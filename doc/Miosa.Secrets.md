# `Miosa.Secrets`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/secrets.ex#L1)

Tenant-wide egress secret and OAuth credential vault.

Backed by `/api/v1/egress/secrets`, `/api/v1/egress/bindings`, and
`/api/v1/egress/oauth/*`.

Secrets are encrypted at rest and can be injected into sandboxes or
computers as environment variables via **bindings**. The OAuth connect
flow creates secrets automatically once the user completes the grant.

## Client-level usage

    client = Miosa.client("msk_u_...")

    {:ok, secret}  = Miosa.Secrets.set(client, %{name: "gh_token", value: "ghp_..."})
    {:ok, secrets} = Miosa.Secrets.list(client)
    {:ok, secret}  = Miosa.Secrets.get(client, secret_id)
    {:ok, secret}  = Miosa.Secrets.rotate(client, secret_id, %{value: "new_val"})
    :ok            = Miosa.Secrets.delete(client, secret_id)

    {:ok, flow} = Miosa.Secrets.connect(client, "github")
    IO.puts("Authorize at: " <> flow.authorize_url)
    {:ok, result} = Miosa.OauthFlow.wait_for_completion(flow)

## Sandbox-bound usage

See `Miosa.Sandboxes.Secrets` for the resource-scoped variant that
pre-populates `resource_id` and `resource_type="sandbox"`.

# `connect`

```elixir
@spec connect(Miosa.Client.t(), String.t(), map()) ::
  Miosa.Client.result(Miosa.OauthFlow.t())
```

Start an OAuth Connect flow for `provider` (e.g. `"github"`, `"slack"`).

Returns `{:ok, %Miosa.OauthFlow{}}`. The caller must open
`flow.authorize_url` in the end user's browser and then call
`Miosa.OauthFlow.wait_for_completion/2`.

## Options (as map attrs)

  * `:expose_as_env`, `:scope`, `:owner_user_id`, `:external_user_id`,
    `:external_workspace_id`, `:resource_id`, `:resource_type`,
    `:redirect_uri` — all optional.

# `create_binding`

```elixir
@spec create_binding(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Explicitly bind an existing secret to a resource.

## Required attrs

  * `:secret_id`
  * `:resource_id`
  * `:resource_type` — `"sandbox"` or `"computer"`
  * `:expose_as_env` — the environment variable name to inject

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
```

Delete a secret by ID.

Returns `:ok` on success.

# `delete_binding`

```elixir
@spec delete_binding(Miosa.Client.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
```

Delete a binding by ID.

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Fetch a single secret by ID.

# `list`

```elixir
@spec list(Miosa.Client.t(), map()) :: Miosa.Client.result([map()])
```

List secrets for the current tenant.

Accepts optional filter keys as a map: `resource_id`, `resource_type`,
`scope`, `type`, `workspace_id`, `owner_user_id`, `external_user_id`,
`external_workspace_id`.

# `list_bindings`

```elixir
@spec list_bindings(Miosa.Client.t(), map()) :: Miosa.Client.result([map()])
```

List bindings. Accepts optional filters: `resource_id`, `resource_type`,
`secret_id`.

# `providers`

```elixir
@spec providers(Miosa.Client.t()) :: Miosa.Client.result([map()])
```

List OAuth providers available to the current tenant.

# `rotate`

```elixir
@spec rotate(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Rotate a secret's value.

`attrs` should contain at minimum `:value`. Optional: `:refresh_token`,
`:expires_at`.

# `set`

```elixir
@spec set(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Create or upsert a secret.

## Required attrs

  * `:name` — identifier for the secret.
  * `:value` — plaintext value to encrypt.

## Optional attrs

  * `:type` — `"api_key"` (default), `"oauth_token"`, `"env_var"`, etc.
  * `:scope` — `"user"` (default) or `"workspace"`.
  * `:expose_as_env` — when provided alongside `:resource_id`, the backend
    also creates a binding so the value is injected as this env-var name.
  * `:workspace_id`, `:owner_user_id`, `:external_user_id`,
    `:external_workspace_id` — attribution fields.
  * `:resource_id`, `:resource_type` — scope to a specific resource.
  * `:refresh_token`, `:expires_at` — OAuth token fields.
  * `:metadata` — arbitrary map stored alongside the secret.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
