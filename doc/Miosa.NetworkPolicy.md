# `Miosa.NetworkPolicy`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/network_policy.ex#L1)

Read and write the network egress/ingress policy for a MIOSA computer.

A network policy controls which hosts and ports a computer can reach on the
public internet. The default policy allows all outbound traffic.

## Example

    {:ok, policy} = Miosa.NetworkPolicy.get(client, computer_id)

    {:ok, policy} = Miosa.NetworkPolicy.set(client, computer_id, %{
      rules: [
        %{direction: "egress", action: "allow", host: "api.example.com", port: 443},
        %{direction: "egress", action: "deny",  host: "*", port: "*"}
      ]
    })

    :ok = Miosa.NetworkPolicy.reset(client, computer_id)

# `policy_params`

```elixir
@type policy_params() :: %{rules: [rule_params()]}
```

# `rule_params`

```elixir
@type rule_params() :: %{
  :direction =&gt; String.t(),
  :action =&gt; String.t(),
  optional(:host) =&gt; String.t(),
  optional(:port) =&gt; String.t() | pos_integer()
}
```

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t()) ::
  Miosa.Client.result(Miosa.Types.NetworkPolicy.t())
```

Returns the current network policy for a computer.

# `reset`

```elixir
@spec reset(Miosa.Client.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
```

Resets the network policy to the default (allow all outbound) for a computer.

# `set`

```elixir
@spec set(Miosa.Client.t(), String.t(), policy_params()) ::
  Miosa.Client.result(Miosa.Types.NetworkPolicy.t())
```

Replaces the network policy for a computer.

The supplied rules fully replace the existing policy.

## Params

  * `:rules` — Required. List of rule maps with `:direction`, `:action`,
    and optionally `:host` and `:port`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
