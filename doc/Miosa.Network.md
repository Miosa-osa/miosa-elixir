# `Miosa.Network`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.1.0/lib/miosa/network.ex#L1)

Tenant-wide egress network policy and allowlist management.

Backed by `/api/v1/egress/policies`, `/api/v1/egress/allowlist`, and
`/api/v1/egress/audit/suggestions`.

The egress firewall operates in two modes:

  * **`enforce`** — denied requests are actively blocked.
  * **`audit_only`** — requests are logged but never blocked (observe mode).

Use `observe/2` to run in shadow mode during rollout, then `lockdown/2`
when you are ready to enforce.

## Client-level usage

    client = Miosa.client("msk_u_...")

    {:ok, rule}    = Miosa.Network.allow(client, "api.github.com")
    {:ok, rule}    = Miosa.Network.deny(client, "suspicious.host.io")
    {:ok, policy}  = Miosa.Network.lockdown(client)
    {:ok, policy}  = Miosa.Network.observe(client)
    {:ok, items}   = Miosa.Network.suggestions(client)
    {:ok, policies}= Miosa.Network.policies(client)
    {:ok, rules}   = Miosa.Network.rules(client, policy_id)

## Sandbox-bound usage

See `Miosa.Sandboxes.Network` for the resource-scoped variant.

# `allow`

```elixir
@spec allow(Miosa.Client.t(), String.t(), keyword()) :: Miosa.Client.result(map())
```

Add an `allow` rule for `host` to the tenant egress allowlist.

## Options (as keyword list)

  * `:methods` — list of HTTP methods to allow. `nil` = all.
  * `:path_glob` — glob pattern to restrict path scope.
  * `:policy_id` — attach to a named policy.
  * `:resource_id`, `:resource_type` — scope to a specific resource.
  * `:note` — human-readable description.

# `create_policy`

```elixir
@spec create_policy(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Create a new egress policy.

## Required attrs

  * `:name`

## Optional attrs

  * `:mode` — `"enforce"` (default) or `"audit_only"`.
  * `:default_effect` — `"deny"` (default) or `"allow"`.
  * `:resource_id`, `:resource_type` — scope to a specific resource.
  * `:description`

# `deny`

```elixir
@spec deny(Miosa.Client.t(), String.t(), keyword()) :: Miosa.Client.result(map())
```

Add a `deny` rule for `host` to the tenant egress allowlist.

Accepts the same options as `allow/3`.

# `lockdown`

```elixir
@spec lockdown(
  Miosa.Client.t(),
  keyword()
) :: Miosa.Client.result(map())
```

Set the policy to `mode=enforce` — denied requests are blocked.

## Options (keyword)

  * `:policy_id` — target a specific policy. When absent, the tenant
    default policy is patched.
  * `:resource_id`, `:resource_type` — resource-scoped patch.

# `observe`

```elixir
@spec observe(
  Miosa.Client.t(),
  keyword()
) :: Miosa.Client.result(map())
```

Set the policy to `mode=audit_only` — requests are logged but not blocked.

Accepts the same options as `lockdown/2`.

# `policies`

```elixir
@spec policies(
  Miosa.Client.t(),
  keyword()
) :: Miosa.Client.result([map()])
```

List egress policies.

Accepts optional filters as a keyword list.

# `remove_rule`

```elixir
@spec remove_rule(Miosa.Client.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
```

Delete an allowlist rule by ID.

# `rules`

```elixir
@spec rules(Miosa.Client.t(), String.t() | nil, keyword()) ::
  Miosa.Client.result([map()])
```

List allowlist rules.

Accepts optional filters as a keyword list: `policy_id`, `resource_id`,
`resource_type`.

# `suggestions`

```elixir
@spec suggestions(
  Miosa.Client.t(),
  keyword()
) :: Miosa.Client.result([map()])
```

Return AI-generated allowlist suggestions based on recent denied egress traffic.

## Options (keyword)

  * `:resource_id`, `:resource_type` — scope to a specific resource.
  * `:since` — lookback window, e.g. `"7d"` (default), `"24h"`.

# `update_policy`

```elixir
@spec update_policy(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Update an existing egress policy.

`attrs` may include `:mode`, `:default_effect`, `:name`, `:description`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
