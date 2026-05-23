defmodule Miosa.Settings do
  @moduledoc """
  Tenant settings — workspace config, branding, and BYOK provider keys.

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

      {:ok, settings} = Miosa.Settings.get(client)
      {:ok, _updated} = Miosa.Settings.update(client, %{default_region: "us-east"})
  """

  alias Miosa.Client

  # ── Main settings ────────────────────────────────────────────────────────────

  @doc "Get the current tenant settings."
  @spec get(Client.t()) :: Client.result(map())
  def get(client) do
    Client.get(client, "/settings")
  end

  @doc """
  Update tenant settings.

  Pass any settable fields as a map.
  """
  @spec update(Client.t(), map()) :: Client.result(map())
  def update(client, attrs) when is_map(attrs) do
    Client.put(client, "/settings", strip_nil(attrs))
  end

  # ── Branding ─────────────────────────────────────────────────────────────────

  @doc "Get tenant branding (logo, colors, custom wordmark)."
  @spec get_branding(Client.t()) :: Client.result(map())
  def get_branding(client) do
    Client.get(client, "/settings/branding")
  end

  @doc "Update tenant branding."
  @spec update_branding(Client.t(), map()) :: Client.result(map())
  def update_branding(client, attrs) when is_map(attrs) do
    Client.put(client, "/settings/branding", strip_nil(attrs))
  end

  # ── Read-only reference data ──────────────────────────────────────────────────

  @doc "Get tenant-scoped compute pricing."
  @spec compute_pricing(Client.t()) :: Client.result(map())
  def compute_pricing(client) do
    Client.get(client, "/settings/compute-pricing")
  end

  @doc "Get tenant-scoped GPU pricing."
  @spec gpu_pricing(Client.t()) :: Client.result(map())
  def gpu_pricing(client) do
    Client.get(client, "/settings/gpu-pricing")
  end

  @doc "List models available to this tenant."
  @spec available_models(Client.t()) :: Client.result(map())
  def available_models(client) do
    Client.get(client, "/settings/available-models")
  end

  @doc "List regions enabled for this tenant."
  @spec regions(Client.t()) :: Client.result(map())
  def regions(client) do
    Client.get(client, "/settings/regions")
  end

  # ── BYOK provider keys ────────────────────────────────────────────────────────

  @doc "List tenant-level BYOK provider keys (Anthropic, OpenAI, etc.)."
  @spec list_provider_keys(Client.t()) :: Client.result(map())
  def list_provider_keys(client) do
    Client.get(client, "/settings/provider-keys")
  end

  @doc """
  Create or update a BYOK provider key.

  Required: `provider` (e.g. `"anthropic"`) and `attrs` map containing at
  minimum `%{key: "sk-..."}`.
  """
  @spec upsert_provider_key(Client.t(), String.t(), map()) :: Client.result(map())
  def upsert_provider_key(client, provider, attrs) when is_binary(provider) and is_map(attrs) do
    Client.put(client, "/settings/provider-keys/" <> provider, strip_nil(attrs))
  end

  @doc "Delete a BYOK provider key by provider name."
  @spec delete_provider_key(Client.t(), String.t()) :: Client.result(map())
  def delete_provider_key(client, provider) when is_binary(provider) do
    Client.delete(client, "/settings/provider-keys/" <> provider)
  end

  # ── Helpers ───────────────────────────────────────────────────────────────────

  defp strip_nil(map) when is_map(map) do
    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end
end
