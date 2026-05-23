defmodule Miosa.ProviderDefaults do
  @moduledoc """
  Admin LLM provider routing config.

  Routes live under `/api/v1/admin/provider-defaults` and per-tenant
  overrides under `/api/v1/admin/tenants/:id/provider-config`. Requires an
  admin credential (`msk_a_*` / `msk_p_*` or admin JWT).
  """

  alias Miosa.Client

  @doc """
  Get the current fleet-wide provider defaults (GET `/admin/provider-defaults`).
  """
  @spec list(Client.t()) :: Client.result(map())
  def list(%Client{} = client) do
    client
    |> Client.get("/admin/provider-defaults")
    |> unwrap()
  end

  @doc """
  Return the defaults entry for a single provider name, or `{:ok, %{}}` if not found.
  """
  @spec get(Client.t(), String.t()) :: Client.result(map())
  def get(%Client{} = client, provider) when is_binary(provider) do
    case list(client) do
      {:ok, data} ->
        providers = Map.get(data, "providers") || data
        {:ok, Map.get(providers, provider, %{})}

      err ->
        err
    end
  end

  @doc """
  Replace the fleet-wide defaults (PUT `/admin/provider-defaults`).
  """
  @spec update(Client.t(), map()) :: Client.result(map())
  def update(%Client{} = client, attrs) when is_map(attrs) do
    body = for {k, v} <- attrs, v != nil, into: %{}, do: {to_string(k), v}

    client
    |> Client.put("/admin/provider-defaults", body)
    |> unwrap()
  end

  @doc """
  Get per-tenant provider config override (GET `/admin/tenants/:tenant_id/provider-config`).
  """
  @spec get_tenant(Client.t(), String.t()) :: Client.result(map())
  def get_tenant(%Client{} = client, tenant_id) when is_binary(tenant_id) do
    client
    |> Client.get("/admin/tenants/#{tenant_id}/provider-config")
    |> unwrap()
  end

  @doc """
  Set per-tenant provider config override (PUT `/admin/tenants/:tenant_id/provider-config`).
  """
  @spec set_tenant(Client.t(), String.t(), map()) :: Client.result(map())
  def set_tenant(%Client{} = client, tenant_id, attrs)
      when is_binary(tenant_id) and is_map(attrs) do
    body = for {k, v} <- attrs, v != nil, into: %{}, do: {to_string(k), v}

    client
    |> Client.put("/admin/tenants/#{tenant_id}/provider-config", body)
    |> unwrap()
  end

  @doc """
  Delete per-tenant provider config override (DELETE `/admin/tenants/:tenant_id/provider-config`).
  """
  @spec reset_tenant(Client.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def reset_tenant(%Client{} = client, tenant_id) when is_binary(tenant_id) do
    case Client.delete(client, "/admin/tenants/#{tenant_id}/provider-config") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap({:ok, %{"data" => data}}), do: {:ok, data}
  defp unwrap({:ok, %{"defaults" => data}}), do: {:ok, data}
  defp unwrap({:ok, %{"provider_defaults" => data}}), do: {:ok, data}
  defp unwrap({:ok, %{"config" => data}}), do: {:ok, data}
  defp unwrap({:ok, body}), do: {:ok, body}
  defp unwrap(err), do: err
end
