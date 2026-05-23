defmodule Miosa.FlatCustomDomains do
  @moduledoc """
  Tenant-scoped custom domain management across all computers and deployments.

  This is the flat listing at `/custom-domains`. Per-deployment domain
  management lives in `Miosa.Deployments` (e.g. `add_domain/3`, `list_domains/2`).

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

      {:ok, domain} = Miosa.FlatCustomDomains.create(client, %{
        domain: "app.example.com",
        target_id: "depl_abc123",
        target_type: "deployment"
      })

      {:ok, _} = Miosa.FlatCustomDomains.list(client)
  """

  alias Miosa.Client

  @doc """
  List all custom domains for the authenticated tenant.

  Accepts optional filters as a keyword list or map (e.g. `:limit`, `:cursor`,
  `:target_type`).
  """
  @spec list(Client.t(), keyword() | map()) :: Client.result(map())
  def list(client, filters \\ []) do
    query = filters |> normalize() |> build_query()
    Client.get(client, "/custom-domains" <> query)
  end

  @doc """
  Attach a custom domain.

  Required: `:domain`. Optional: `:target_id`, `:target_type`, `:redirect_policy`,
  attribution fields, `:idempotency_key`.
  """
  @spec create(Client.t(), map()) :: Client.result(map())
  def create(client, attrs) when is_map(attrs) do
    idem = pop_idempotency(attrs)
    Client.post(client, "/custom-domains", strip_nil(attrs), headers: [{"idempotency-key", idem}])
  end

  @doc "Delete a custom domain by ID."
  @spec delete(Client.t(), String.t()) :: Client.result(map())
  def delete(client, domain_id) when is_binary(domain_id) do
    Client.delete(client, "/custom-domains/" <> domain_id)
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
