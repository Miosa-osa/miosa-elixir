defmodule Miosa.HealthChecks do
  @moduledoc """
  Health checks — uptime monitoring for URLs and TCP endpoints.

  Mutating calls (create, update) send an `Idempotency-Key` header automatically.

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

      {:ok, check} = Miosa.HealthChecks.create(client, %{
        name: "API health",
        url: "https://api.example.com/health",
        interval_seconds: 60
      })

      {:ok, _} = Miosa.HealthChecks.get(client, check["id"])
  """

  alias Miosa.Client

  @doc """
  List health checks for the authenticated tenant.

  Accepts optional filters as a keyword list or map (e.g. `:limit`, `:cursor`).
  """
  @spec list(Client.t(), keyword() | map()) :: Client.result(map())
  def list(client, filters \\ []) do
    query = filters |> normalize() |> build_query()
    Client.get(client, "/health-checks" <> query)
  end

  @doc "Fetch a health check by ID."
  @spec get(Client.t(), String.t()) :: Client.result(map())
  def get(client, check_id) when is_binary(check_id) do
    Client.get(client, "/health-checks/" <> check_id)
  end

  @doc """
  Create a health check.

  Required: `:name`, `:url`. Optional: `:interval_seconds`, `:timeout_seconds`,
  `:expected_status`, `:method`, `:headers`, `:idempotency_key`.
  """
  @spec create(Client.t(), map()) :: Client.result(map())
  def create(client, attrs) when is_map(attrs) do
    idem = pop_idempotency(attrs)
    Client.post(client, "/health-checks", strip_nil(attrs), headers: [{"idempotency-key", idem}])
  end

  @doc """
  Update a health check.

  Pass any fields to update; nil values are dropped.
  """
  @spec update(Client.t(), String.t(), map()) :: Client.result(map())
  def update(client, check_id, attrs) when is_binary(check_id) and is_map(attrs) do
    Client.patch(client, "/health-checks/" <> check_id, strip_nil(attrs))
  end

  @doc "Delete a health check by ID."
  @spec delete(Client.t(), String.t()) :: Client.result(map())
  def delete(client, check_id) when is_binary(check_id) do
    Client.delete(client, "/health-checks/" <> check_id)
  end

  # ── Helpers ──────────────────────────────────────────────────────────────────

  defp pop_idempotency(attrs) do
    cond do
      is_map(attrs) -> Map.get(attrs, :idempotency_key) || Map.get(attrs, "idempotency_key")
      Keyword.keyword?(attrs) -> Keyword.get(attrs, :idempotency_key)
      true -> nil
    end || generate_idempotency_key()
  end

  defp generate_idempotency_key do
    16 |> :crypto.strong_rand_bytes() |> Base.encode16(case: :lower)
  end

  defp strip_nil(map) when is_map(map) do
    map
    |> Map.delete(:idempotency_key)
    |> Map.delete("idempotency_key")
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

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
