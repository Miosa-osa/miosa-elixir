# `Miosa.Credits`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/credits.ex#L1)

Query credit balance, transaction history, and usage for the authenticated tenant.

Credits are consumed by compute time and AI agent calls. The balance is
shared across all computers and sessions for your account.

## Example

    {:ok, balance} = Miosa.Credits.balance(client)
    IO.puts("Credits remaining: #{balance.balance}")

    {:ok, txns} = Miosa.Credits.transactions(client, limit: 20)
    {:ok, usage} = Miosa.Credits.usage(client)

# `balance`

```elixir
@spec balance(Miosa.Client.t()) :: Miosa.Client.result(Miosa.Types.CreditBalance.t())
```

Returns the current credit balance for the authenticated tenant.

# `transactions`

```elixir
@spec transactions(
  Miosa.Client.t(),
  keyword()
) :: Miosa.Client.result([Miosa.Types.CreditTransaction.t()])
```

Lists credit transactions (debits and credits).

## Options

  * `:limit` — Maximum number of transactions. Defaults to `50`.
  * `:offset` — Pagination offset. Defaults to `0`.
  * `:type` — Filter by type: `"debit"`, `"credit"`, `"promo"`.

# `usage`

```elixir
@spec usage(
  Miosa.Client.t(),
  keyword()
) :: Miosa.Client.result(map())
```

Returns aggregated usage statistics for the tenant.

Returns a raw map as usage schema varies by plan and time period.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
