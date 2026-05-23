defmodule Miosa.CommandCenter do
  @moduledoc """
  Read-only views of the Optimal AI agent fleet.

  Routes live under `/api/v1/command-center/` and require a JWT or
  `msk_u_*` API key.
  """

  alias Miosa.Client

  @doc """
  Top-level fleet snapshot (GET `/command-center`).
  """
  @spec overview(Client.t()) :: Client.result(map())
  def overview(%Client{} = client) do
    client
    |> Client.get("/command-center")
    |> unwrap()
  end

  @doc """
  List all agents in the fleet (GET `/command-center/agents`).
  """
  @spec agents(Client.t()) :: Client.result(list())
  def agents(%Client{} = client) do
    case Client.get(client, "/command-center/agents") do
      {:ok, body} -> {:ok, unwrap_list(body)}
      err -> err
    end
  end

  @doc """
  List currently running agents (GET `/command-center/agents/running`).
  """
  @spec running_agents(Client.t()) :: Client.result(list())
  def running_agents(%Client{} = client) do
    case Client.get(client, "/command-center/agents/running") do
      {:ok, body} -> {:ok, unwrap_list(body)}
      err -> err
    end
  end

  @doc """
  Get fleet-wide metrics snapshot (GET `/command-center/metrics`).
  """
  @spec metrics(Client.t()) :: Client.result(map())
  def metrics(%Client{} = client) do
    client
    |> Client.get("/command-center/metrics")
    |> unwrap()
  end

  @doc """
  List agent execution presets (GET `/command-center/presets`).
  """
  @spec presets(Client.t()) :: Client.result(list())
  def presets(%Client{} = client) do
    case Client.get(client, "/command-center/presets") do
      {:ok, body} -> {:ok, unwrap_list(body)}
      err -> err
    end
  end

  @doc """
  Get agent tier configuration (GET `/command-center/tiers`).
  """
  @spec tiers(Client.t()) :: Client.result(map())
  def tiers(%Client{} = client) do
    client
    |> Client.get("/command-center/tiers")
    |> unwrap()
  end

  @doc """
  Stream live command-center events via SSE (GET `/command-center/events`).

  `callback` is invoked for each event map with keys `type` and `data`.
  Returns `:ok` when the stream closes or `{:error, reason}` on failure.
  """
  @spec events(Client.t(), function()) :: :ok | {:error, Miosa.Error.t()}
  def events(%Client{} = client, callback) when is_function(callback, 1) do
    Client.stream_sse(client, "/command-center/events", callback)
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap_list(%{"data" => list}) when is_list(list), do: list
  defp unwrap_list(%{"agents" => list}) when is_list(list), do: list
  defp unwrap_list(%{"running" => list}) when is_list(list), do: list
  defp unwrap_list(%{"presets" => list}) when is_list(list), do: list
  defp unwrap_list(%{"tiers" => list}) when is_list(list), do: list
  defp unwrap_list(%{"items" => list}) when is_list(list), do: list
  defp unwrap_list(list) when is_list(list), do: list
  defp unwrap_list(_), do: []

  defp unwrap({:ok, %{"data" => data}}), do: {:ok, data}
  defp unwrap({:ok, %{"metrics" => data}}), do: {:ok, data}
  defp unwrap({:ok, body}), do: {:ok, body}
  defp unwrap(err), do: err
end
