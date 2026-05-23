# `Miosa.Sandboxes.Network`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/sandboxes/network.ex#L1)

Sandbox-bound view of `Miosa.Network`.

Every call pre-populates `resource_id` with the sandbox's ID and sets
`resource_type` to `"sandbox"`.

## Usage

    {:ok, sandbox} = Miosa.Sandboxes.create(client, %{name: "my-box"})

    {:ok, rule}   = Miosa.Sandboxes.Network.allow(sandbox, client, "api.github.com")
    {:ok, rule}   = Miosa.Sandboxes.Network.deny(sandbox, client, "bad.host.io")
    {:ok, policy} = Miosa.Sandboxes.Network.lockdown(sandbox, client)
    {:ok, policy} = Miosa.Sandboxes.Network.observe(sandbox, client)
    {:ok, items}  = Miosa.Sandboxes.Network.suggestions(sandbox, client)
    {:ok, rules}  = Miosa.Sandboxes.Network.rules(sandbox, client)

The `sandbox` argument may be either a `Miosa.Types.Computer.t()` struct or
a plain binary sandbox ID string.

# `allow`

```elixir
@spec allow(map() | String.t(), Miosa.Client.t(), String.t(), keyword()) ::
  Miosa.Client.result(map())
```

Add an `allow` rule for `host`, scoped to this sandbox.

# `deny`

```elixir
@spec deny(map() | String.t(), Miosa.Client.t(), String.t(), keyword()) ::
  Miosa.Client.result(map())
```

Add a `deny` rule for `host`, scoped to this sandbox.

# `lockdown`

```elixir
@spec lockdown(map() | String.t(), Miosa.Client.t(), keyword()) ::
  Miosa.Client.result(map())
```

Set the policy to `mode=enforce` for this sandbox — denied requests are blocked.

# `observe`

```elixir
@spec observe(map() | String.t(), Miosa.Client.t(), keyword()) ::
  Miosa.Client.result(map())
```

Set the policy to `mode=audit_only` for this sandbox — log but do not block.

# `policies`

```elixir
@spec policies(map() | String.t(), Miosa.Client.t(), keyword()) ::
  Miosa.Client.result([map()])
```

List egress policies scoped to this sandbox.

# `remove_rule`

```elixir
@spec remove_rule(map() | String.t(), Miosa.Client.t(), String.t()) ::
  :ok | {:error, Miosa.Error.t()}
```

Delete an allowlist rule by ID.

# `rules`

```elixir
@spec rules(map() | String.t(), Miosa.Client.t(), keyword()) ::
  Miosa.Client.result([map()])
```

List allowlist rules for this sandbox.

# `suggestions`

```elixir
@spec suggestions(map() | String.t(), Miosa.Client.t(), keyword()) ::
  Miosa.Client.result([map()])
```

Return AI-generated allowlist suggestions for this sandbox.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
