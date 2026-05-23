defmodule Miosa.Benchmarks do
  @moduledoc """
  Admin-triggered platform benchmark runs.

  Routes live under `/api/v1/admin/benchmarks/` and require an admin
  credential (`msk_a_*` / `msk_p_*` or admin JWT). Available run kinds
  include `cold_boot`, `fleet_routing`, `concurrent_create`, and `full_e2e`.
  """

  alias Miosa.Client

  @doc """
  List all benchmark runs (GET `/admin/benchmarks`).

  Accepts optional filter params (e.g. `%{kind: "cold_boot"}`).
  """
  @spec list(Client.t(), map()) :: Client.result(list())
  def list(%Client{} = client, filters \\ %{}) do
    params = for {k, v} <- filters, v != nil, into: %{}, do: {k, v}
    opts = if map_size(params) > 0, do: [params: params], else: []

    case Client.get(client, "/admin/benchmarks", opts) do
      {:ok, body} -> {:ok, unwrap_list(body)}
      err -> err
    end
  end

  @doc """
  Get a benchmark run by ID (GET `/admin/benchmarks/:benchmark_id`).
  """
  @spec get(Client.t(), String.t()) :: Client.result(map())
  def get(%Client{} = client, benchmark_id) when is_binary(benchmark_id) do
    client
    |> Client.get("/admin/benchmarks/#{benchmark_id}")
    |> unwrap()
  end

  @doc """
  Start a new benchmark run (POST `/admin/benchmarks`).

  Pass `kind:` and run-specific options. E.g.:

      Miosa.Benchmarks.create(client, %{kind: "cold_boot", count: 10})
  """
  @spec create(Client.t(), map()) :: Client.result(map())
  def create(%Client{} = client, attrs) when is_map(attrs) do
    body = for {k, v} <- attrs, v != nil, into: %{}, do: {to_string(k), v}

    client
    |> Client.post("/admin/benchmarks", body)
    |> unwrap()
  end

  @doc """
  Cancel a running benchmark (POST `/admin/benchmarks/:benchmark_id/cancel`).
  """
  @spec cancel(Client.t(), String.t()) :: Client.result(map())
  def cancel(%Client{} = client, benchmark_id) when is_binary(benchmark_id) do
    client
    |> Client.post("/admin/benchmarks/#{benchmark_id}/cancel")
    |> unwrap()
  end

  @doc """
  Return per-iteration timing samples for a benchmark run
  (GET `/admin/benchmarks/:benchmark_id/samples`).
  """
  @spec samples(Client.t(), String.t(), map()) :: Client.result(list())
  def samples(%Client{} = client, benchmark_id, filters \\ %{}) when is_binary(benchmark_id) do
    params = for {k, v} <- filters, v != nil, into: %{}, do: {k, v}
    opts = if map_size(params) > 0, do: [params: params], else: []

    case Client.get(client, "/admin/benchmarks/#{benchmark_id}/samples", opts) do
      {:ok, body} -> {:ok, unwrap_list(body)}
      err -> err
    end
  end

  @doc """
  Compare two benchmark runs (POST `/admin/benchmarks/compare`).
  """
  @spec compare(Client.t(), String.t(), String.t(), map()) :: Client.result(map())
  def compare(%Client{} = client, left_id, right_id, opts \\ %{})
      when is_binary(left_id) and is_binary(right_id) do
    body =
      opts
      |> Enum.reduce(%{"left_id" => left_id, "right_id" => right_id}, fn {k, v}, acc ->
        if v != nil, do: Map.put(acc, to_string(k), v), else: acc
      end)

    client
    |> Client.post("/admin/benchmarks/compare", body)
    |> unwrap()
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap_list(%{"data" => list}) when is_list(list), do: list
  defp unwrap_list(%{"benchmarks" => list}) when is_list(list), do: list
  defp unwrap_list(%{"samples" => list}) when is_list(list), do: list
  defp unwrap_list(%{"items" => list}) when is_list(list), do: list
  defp unwrap_list(list) when is_list(list), do: list
  defp unwrap_list(_), do: []

  defp unwrap({:ok, %{"data" => data}}), do: {:ok, data}
  defp unwrap({:ok, %{"benchmarks" => data}}), do: {:ok, data}
  defp unwrap({:ok, body}), do: {:ok, body}
  defp unwrap(err), do: err
end
