# `Miosa.CustomDomains`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/custom_domains.ex#L1)

Register and verify custom domains for MIOSA computers.

Custom domains allow you to expose a service running inside a computer at
a user-friendly hostname (e.g. `app.example.com`) instead of the default
generated URL.

## Workflow

1. `register/3` — claim the domain against a computer + port.
2. Follow the DNS instructions returned in the `CustomDomain` struct.
3. `verify/3` — trigger domain verification; status transitions to `:active`.
4. `delete/3` — remove the domain when no longer needed.

## Example

    {:ok, domain} = Miosa.CustomDomains.register(client, computer_id, %{
      domain: "app.example.com",
      port: 3000
    })

    {:ok, domains} = Miosa.CustomDomains.list(client, computer_id)
    {:ok, domain} = Miosa.CustomDomains.verify(client, computer_id, domain.id)
    :ok = Miosa.CustomDomains.delete(client, computer_id, domain.id)

# `register_params`

```elixir
@type register_params() :: %{
  :domain =&gt; String.t(),
  optional(:port) =&gt; pos_integer(),
  optional(:tls) =&gt; boolean()
}
```

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t(), String.t()) ::
  :ok | {:error, Miosa.Error.t()}
```

Removes a custom domain registration.

In-flight requests to the domain will immediately return 404 after deletion.

# `list`

```elixir
@spec list(Miosa.Client.t(), String.t()) ::
  Miosa.Client.result([Miosa.Types.CustomDomain.t()])
```

Lists all custom domains registered for a computer.

# `register`

```elixir
@spec register(Miosa.Client.t(), String.t(), register_params()) ::
  Miosa.Client.result(Miosa.Types.CustomDomain.t())
```

Registers a custom domain for a computer.

## Params

  * `:domain` — Required. The fully-qualified domain name.
  * `:port` — Port inside the computer to route traffic to. Defaults to `80`.
  * `:tls` — Whether to provision TLS. Defaults to `true`.

Returns a `CustomDomain` struct whose `:dns_instructions` field contains
the CNAME or A-record value to configure with your DNS provider.

# `verify`

```elixir
@spec verify(Miosa.Client.t(), String.t(), String.t()) ::
  Miosa.Client.result(Miosa.Types.CustomDomain.t())
```

Triggers domain ownership verification.

The API checks that the required DNS record is in place. On success the
domain transitions to `:active` status.

Returns the updated `CustomDomain` struct.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
