defmodule Miosa.Integrations do
  @moduledoc """
  OAuth account-level integrations — GitHub, Slack, Linear, Discord.

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

      {:ok, integrations} = Miosa.Integrations.list(client)
      {:ok, %{"url" => url}} = Miosa.Integrations.start(client, "github")
  """

  alias Miosa.Client

  # ── Catalog + active connections ─────────────────────────────────────────────

  @doc "List active OAuth integrations for the tenant."
  @spec list(Client.t()) :: Client.result(map())
  def list(client) do
    Client.get(client, "/integrations")
  end

  @doc "List available providers in the integration catalog."
  @spec catalog(Client.t()) :: Client.result(map())
  def catalog(client) do
    Client.get(client, "/integrations/catalog")
  end

  # ── OAuth flow ────────────────────────────────────────────────────────────────

  @doc "Begin the OAuth flow for a provider — returns an authorize URL."
  @spec start(Client.t(), String.t()) :: Client.result(map())
  def start(client, provider) when is_binary(provider) do
    Client.get(client, "/integrations/#{provider}/start")
  end

  @doc "Force-refresh the access token for a connected provider."
  @spec refresh(Client.t(), String.t()) :: Client.result(map())
  def refresh(client, provider) when is_binary(provider) do
    Client.post(client, "/integrations/#{provider}/refresh", nil)
  end

  @doc "Disconnect (revoke) an integration by provider name."
  @spec disconnect(Client.t(), String.t()) :: Client.result(map())
  def disconnect(client, provider) when is_binary(provider) do
    Client.delete(client, "/integrations/" <> provider)
  end

  # ── GitHub ────────────────────────────────────────────────────────────────────

  @doc "List GitHub repositories accessible to this integration."
  @spec github_repos(Client.t()) :: Client.result(map())
  def github_repos(client) do
    Client.get(client, "/integrations/github/repos")
  end

  @doc "List configured GitHub deploy (SSH) keys."
  @spec github_ssh_keys(Client.t()) :: Client.result(map())
  def github_ssh_keys(client) do
    Client.get(client, "/integrations/github/ssh-keys")
  end

  # ── Slack ─────────────────────────────────────────────────────────────────────

  @doc "Send a test message to the connected Slack channel."
  @spec slack_send_test(Client.t(), map()) :: Client.result(map())
  def slack_send_test(client, body \\ %{}) when is_map(body) do
    Client.post(client, "/integrations/slack/send-test", strip_nil(body))
  end

  # ── Discord ───────────────────────────────────────────────────────────────────

  @doc "Send a test message to the connected Discord channel."
  @spec discord_send_test(Client.t(), map()) :: Client.result(map())
  def discord_send_test(client, body \\ %{}) when is_map(body) do
    Client.post(client, "/integrations/discord/send-test", strip_nil(body))
  end

  # ── Linear ────────────────────────────────────────────────────────────────────

  @doc "Begin the Linear OAuth flow."
  @spec linear_start(Client.t()) :: Client.result(map())
  def linear_start(client) do
    Client.get(client, "/integrations/linear/start")
  end

  @doc "Create a Linear issue via the connected workspace."
  @spec linear_create_issue(Client.t(), map()) :: Client.result(map())
  def linear_create_issue(client, attrs) when is_map(attrs) do
    Client.post(client, "/integrations/linear/create-issue", strip_nil(attrs))
  end

  # ── Helpers ───────────────────────────────────────────────────────────────────

  defp strip_nil(map) when is_map(map) do
    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end
end
