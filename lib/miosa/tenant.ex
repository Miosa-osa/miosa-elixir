defmodule Miosa.Tenant do
  @moduledoc """
  Current tenant info — plan limits and live usage counters.

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

      {:ok, plan} = Miosa.Tenant.current(client)
      IO.inspect(plan["plan"])
  """

  alias Miosa.Client

  @doc """
  Get the current tenant's plan, limits, and live usage counters.
  """
  @spec current(Client.t()) :: Client.result(map())
  def current(client) do
    Client.get(client, "/tenant/plan")
  end

  @doc "Get the current tenant preview domain configuration."
  @spec get_preview_domain(Client.t()) :: Client.result(map())
  def get_preview_domain(client) do
    Client.get(client, "/tenant/preview-domain")
  end

  @doc "Set the current tenant preview domain."
  @spec set_preview_domain(Client.t(), String.t()) :: Client.result(map())
  def set_preview_domain(client, domain) when is_binary(domain) do
    Client.put(client, "/tenant/preview-domain", %{domain: domain})
  end

  @doc "Ask the API to verify the current tenant preview domain DNS state."
  @spec verify_preview_domain(Client.t()) :: Client.result(map())
  def verify_preview_domain(client) do
    Client.post(client, "/tenant/preview-domain/verify", nil)
  end

  @doc "Update current tenant branding."
  @spec set_branding(Client.t(), map()) :: Client.result(map())
  def set_branding(client, attrs) when is_map(attrs) do
    Client.put(client, "/tenant/branding", strip_nil(attrs))
  end

  @doc "Get current tenant branding."
  @spec get_branding(Client.t()) :: Client.result(map())
  def get_branding(client) do
    Client.get(client, "/tenant/branding")
  end

  defp strip_nil(map) when is_map(map) do
    map
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
