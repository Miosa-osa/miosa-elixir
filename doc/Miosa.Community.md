# `Miosa.Community`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/community.ex#L1)

Community template and agent catalog with install and rate actions.

Routes live under `/api/v1/community/` and require a JWT.

# `get_agent`

```elixir
@spec get_agent(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Get a community agent by ID (GET `/community/agents/:agent_id`).

# `get_template`

```elixir
@spec get_template(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Get a community template by ID (GET `/community/templates/:template_id`).

# `install_template`

```elixir
@spec install_template(Miosa.Client.t(), String.t(), map()) ::
  Miosa.Client.result(map())
```

Install a community template into the caller's tenant
(POST `/community/templates/:template_id/install`).

# `list_agents`

```elixir
@spec list_agents(Miosa.Client.t(), map()) :: Miosa.Client.result(list())
```

List community agents (GET `/community/agents`).

Accepts optional filter params.

# `list_templates`

```elixir
@spec list_templates(Miosa.Client.t(), map()) :: Miosa.Client.result(list())
```

List community templates (GET `/community/templates`).

Accepts optional filter params.

# `rate_template`

```elixir
@spec rate_template(Miosa.Client.t(), String.t(), 1..5, map()) ::
  Miosa.Client.result(map())
```

Rate a community template 1-5 (POST `/community/templates/:template_id/rate`).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
