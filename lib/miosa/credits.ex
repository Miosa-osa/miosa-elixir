defmodule Miosa.Credits do
  @moduledoc """
  Query credit balance, transaction history, and usage for the authenticated tenant.

  Credits are consumed by compute time and AI agent calls. The balance is
  shared across all computers and sessions for your account.

  ## Example

      {:ok, balance} = Miosa.Credits.balance(client)
      IO.puts("Credits remaining: \#{balance.balance}")

      {:ok, txns} = Miosa.Credits.transactions(client, limit: 20)
      {:ok, usage} = Miosa.Credits.usage(client)

  """

  alias Miosa.{Client, Types}

  @doc """
  Returns the current credit balance for the authenticated tenant.
  """
  @spec balance(Client.t()) :: Client.result(Types.CreditBalance.t())
  def balance(%Client{} = client) do
    case Client.get(client, "/credits/balance") do
      {:ok, body} -> {:ok, Types.CreditBalance.from_map(body)}
      {:error, _} = err -> err
    end
  end

  @doc """
  Lists credit transactions (debits and credits).

  ## Options

    * `:limit` — Maximum number of transactions. Defaults to `50`.
    * `:offset` — Pagination offset. Defaults to `0`.
    * `:type` — Filter by type: `"debit"`, `"credit"`, `"promo"`.

  """
  @spec transactions(Client.t(), keyword()) :: Client.result([Types.CreditTransaction.t()])
  def transactions(%Client{} = client, opts \\ []) do
    params =
      opts
      |> Keyword.take([:limit, :offset, :type])
      |> Map.new()

    case Client.get(client, "/credits/transactions", params: params) do
      {:ok, body} ->
        txns =
          body
          |> get_list()
          |> Enum.map(&Types.CreditTransaction.from_map/1)

        {:ok, txns}

      {:error, _} = err ->
        err
    end
  end

  @doc """
  Returns aggregated usage statistics for the tenant.

  Returns a raw map as usage schema varies by plan and time period.
  """
  @spec usage(Client.t(), keyword()) :: Client.result(map())
  def usage(%Client{} = client, opts \\ []) do
    params = opts |> Keyword.take([:from, :to, :period]) |> Map.new()
    Client.get(client, "/credits/usage", params: params)
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp get_list(%{"data" => list}) when is_list(list), do: list
  defp get_list(%{"transactions" => list}) when is_list(list), do: list
  defp get_list(list) when is_list(list), do: list
  defp get_list(_), do: []
end
