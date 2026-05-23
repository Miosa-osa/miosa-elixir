defmodule Miosa.ProjectAuth do
  @moduledoc """
  Project Auth — built-in authentication for generated apps inside
  sandboxes and deployments.

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

      {:ok, status} = Miosa.ProjectAuth.status(client)
      {:ok, _} = Miosa.ProjectAuth.enable(client, %{provider: "email"})
  """

  alias Miosa.Client

  @doc "Get the current project-auth status and configuration."
  @spec status(Client.t()) :: Client.result(map())
  def status(client) do
    Client.get(client, "/project-auth/status")
  end

  @doc """
  Enable project auth.

  Pass an optional config map (e.g. `%{provider: "email"}`).
  """
  @spec enable(Client.t(), map()) :: Client.result(map())
  def enable(client, config \\ %{}) when is_map(config) do
    body = strip_nil(config)
    Client.post(client, "/project-auth/enable", if(body == %{}, do: nil, else: body))
  end

  @doc "Disable project auth."
  @spec disable(Client.t()) :: Client.result(map())
  def disable(client) do
    Client.post(client, "/project-auth/disable", nil)
  end

  @doc "Update project-auth configuration."
  @spec update(Client.t(), map()) :: Client.result(map())
  def update(client, config) when is_map(config) do
    Client.patch(client, "/project-auth/config", strip_nil(config))
  end

  # ── Helpers ───────────────────────────────────────────────────────────────────

  defp strip_nil(map) when is_map(map) do
    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end
end
