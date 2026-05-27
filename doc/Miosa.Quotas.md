# `Miosa.Quotas`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.1.0/lib/miosa/quotas.ex#L1)

Per-`external_user_id` quota management — override the tenant defaults for
individual end-users of your platform.

Wraps:
  * `GET    /api/v1/quotas/external/:external_user_id` — get/2
  * `PUT    /api/v1/quotas/external/:external_user_id` — set/3
  * `DELETE /api/v1/quotas/external/:external_user_id` — delete/2

## Example

    client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

    {:ok, _} = Miosa.Quotas.set(client, "user-123", %{
      max_sandboxes: 5,
      max_concurrent: 2,
      max_storage_gb: 20,
      max_credit_cents: 5000
    })

    {:ok, quota} = Miosa.Quotas.get(client, "user-123")
    IO.inspect(quota)

    :ok = Miosa.Quotas.delete(client, "user-123")

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
```

Revert an external user's quota to the tenant default.

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Get current quota limits + usage for an external user.

# `set`

```elixir
@spec set(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Set quota overrides for an external user.

Accepted keys (atom or string): `:max_sandboxes`, `:max_concurrent`,
`:max_storage_gb`, `:max_credit_cents`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
