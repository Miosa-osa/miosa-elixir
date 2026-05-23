defmodule Miosa.Analytics do
  @moduledoc """
  Analytics — admin-scoped overview and timeseries metrics.

  Requires an admin (`msk_a_` / `msk_p_`) key.

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_ADMIN_KEY"))

      {:ok, overview} = Miosa.Analytics.overview(client)
      {:ok, ts} = Miosa.Analytics.timeseries(client, %{metric: "computers", period: "7d"})
  """

  alias Miosa.Client

  @doc """
  Get the platform analytics overview.

  Accepts optional filters as a keyword list or map (e.g. `:period`, `:tenant_id`).
  """
  @spec overview(Client.t(), keyword() | map()) :: Client.result(map())
  def overview(client, filters \\ []) do
    query = filters |> normalize() |> build_query()
    Client.get(client, "/analytics/overview" <> query)
  end

  @doc """
  Get a timeseries for a metric over a period.

  Common options: `:metric` (e.g. `"computers"`), `:period` (e.g. `"7d"`).
  Accepts any additional filters supported by the API.
  """
  @spec timeseries(Client.t(), keyword() | map()) :: Client.result(map())
  def timeseries(client, filters \\ []) do
    query = filters |> normalize() |> build_query()
    Client.get(client, "/analytics/timeseries" <> query)
  end

  # ── Helpers ───────────────────────────────────────────────────────────────────

  defp normalize(filters) when is_list(filters), do: Map.new(filters)
  defp normalize(filters) when is_map(filters), do: filters

  defp build_query(filters) when filters == %{}, do: ""

  defp build_query(filters) do
    "?" <>
      (filters
       |> Enum.reject(fn {_k, v} -> is_nil(v) end)
       |> Enum.map(fn {k, v} -> "#{k}=#{URI.encode_www_form(to_string(v))}" end)
       |> Enum.join("&"))
  end
end
