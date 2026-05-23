defmodule Miosa.ProjectIntegrations do
  @moduledoc """
  Per-project integrations — Stripe, Resend, Twilio, and similar third-party
  provider keys injected as env vars into sandbox/deployment VMs at boot.

  Credentials are encrypted at rest.

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

      {:ok, catalog} = Miosa.ProjectIntegrations.catalog(client)
      {:ok, integration} = Miosa.ProjectIntegrations.create(client, %{
        provider: "stripe",
        secret_key: "sk_live_..."
      })
  """

  alias Miosa.Client

  @doc """
  List project integrations.

  Accepts optional filters as a keyword list or map.
  """
  @spec list(Client.t(), keyword() | map()) :: Client.result(map())
  def list(client, filters \\ []) do
    query = filters |> normalize() |> build_query()
    Client.get(client, "/project-integrations" <> query)
  end

  @doc "List supported providers and their configuration schemas."
  @spec catalog(Client.t()) :: Client.result(map())
  def catalog(client) do
    Client.get(client, "/project-integrations/catalog")
  end

  @doc "Get a project integration by ID."
  @spec get(Client.t(), String.t()) :: Client.result(map())
  def get(client, integration_id) when is_binary(integration_id) do
    Client.get(client, "/project-integrations/" <> integration_id)
  end

  @doc "Create a project integration."
  @spec create(Client.t(), map()) :: Client.result(map())
  def create(client, attrs) when is_map(attrs) do
    Client.post(client, "/project-integrations", strip_nil(attrs))
  end

  @doc "Update a project integration by ID."
  @spec update(Client.t(), String.t(), map()) :: Client.result(map())
  def update(client, integration_id, attrs)
      when is_binary(integration_id) and is_map(attrs) do
    Client.patch(client, "/project-integrations/" <> integration_id, strip_nil(attrs))
  end

  @doc "Delete a project integration by ID."
  @spec delete(Client.t(), String.t()) :: Client.result(map())
  def delete(client, integration_id) when is_binary(integration_id) do
    Client.delete(client, "/project-integrations/" <> integration_id)
  end

  # ── Helpers ───────────────────────────────────────────────────────────────────

  defp strip_nil(map) when is_map(map) do
    map
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
