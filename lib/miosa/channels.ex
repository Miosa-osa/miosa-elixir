defmodule Miosa.Channels do
  @moduledoc """
  Notification channels — Slack, Discord, email, and per-channel enable/disable.

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

      {:ok, channels} = Miosa.Channels.list(client)
      {:ok, channel} = Miosa.Channels.create(client, %{type: "slack", webhook_url: "https://..."})
      {:ok, _} = Miosa.Channels.enable(client, channel["id"])
  """

  alias Miosa.Client

  # ── CRUD ─────────────────────────────────────────────────────────────────────

  @doc """
  List all channels for the tenant.

  Accepts optional filters as a keyword list or map.
  """
  @spec list(Client.t(), keyword() | map()) :: Client.result(map())
  def list(client, filters \\ []) do
    query = filters |> normalize() |> build_query()
    Client.get(client, "/channels" <> query)
  end

  @doc "Get a single channel by ID."
  @spec get(Client.t(), String.t()) :: Client.result(map())
  def get(client, channel_id) when is_binary(channel_id) do
    Client.get(client, "/channels/" <> channel_id)
  end

  @doc "Create a new notification channel."
  @spec create(Client.t(), map()) :: Client.result(map())
  def create(client, attrs) when is_map(attrs) do
    Client.post(client, "/channels", strip_nil(attrs))
  end

  @doc "Update a channel by ID."
  @spec update(Client.t(), String.t(), map()) :: Client.result(map())
  def update(client, channel_id, attrs) when is_binary(channel_id) and is_map(attrs) do
    Client.patch(client, "/channels/" <> channel_id, strip_nil(attrs))
  end

  @doc "Delete a channel by ID."
  @spec delete(Client.t(), String.t()) :: Client.result(map())
  def delete(client, channel_id) when is_binary(channel_id) do
    Client.delete(client, "/channels/" <> channel_id)
  end

  # ── Notification preferences ─────────────────────────────────────────────────

  @doc "Get notification preferences across all channels."
  @spec list_notifications(Client.t()) :: Client.result(map())
  def list_notifications(client) do
    Client.get(client, "/channels/notifications")
  end

  @doc "Update notification preferences."
  @spec update_notifications(Client.t(), map()) :: Client.result(map())
  def update_notifications(client, prefs) when is_map(prefs) do
    Client.put(client, "/channels/notifications", strip_nil(prefs))
  end

  # ── Enable / disable ─────────────────────────────────────────────────────────

  @doc "Enable a channel by ID."
  @spec enable(Client.t(), String.t()) :: Client.result(map())
  def enable(client, channel_id) when is_binary(channel_id) do
    Client.post(client, "/channels/#{channel_id}/enable", nil)
  end

  @doc "Disable a channel by ID."
  @spec disable(Client.t(), String.t()) :: Client.result(map())
  def disable(client, channel_id) when is_binary(channel_id) do
    Client.post(client, "/channels/#{channel_id}/disable", nil)
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
