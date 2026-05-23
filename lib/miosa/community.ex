defmodule Miosa.Community do
  @moduledoc """
  Community template and agent catalog with install and rate actions.

  Routes live under `/api/v1/community/` and require a JWT.
  """

  alias Miosa.Client

  # ── Agents ─────────────────────────────────────────────────────────────────

  @doc """
  List community agents (GET `/community/agents`).

  Accepts optional filter params.
  """
  @spec list_agents(Client.t(), map()) :: Client.result(list())
  def list_agents(%Client{} = client, filters \\ %{}) do
    params = for {k, v} <- filters, v != nil, into: %{}, do: {k, v}
    opts = if map_size(params) > 0, do: [params: params], else: []

    case Client.get(client, "/community/agents", opts) do
      {:ok, body} -> {:ok, unwrap_list(body)}
      err -> err
    end
  end

  @doc """
  Get a community agent by ID (GET `/community/agents/:agent_id`).
  """
  @spec get_agent(Client.t(), String.t()) :: Client.result(map())
  def get_agent(%Client{} = client, agent_id) when is_binary(agent_id) do
    client
    |> Client.get("/community/agents/#{agent_id}")
    |> unwrap()
  end

  # ── Templates ──────────────────────────────────────────────────────────────

  @doc """
  List community templates (GET `/community/templates`).

  Accepts optional filter params.
  """
  @spec list_templates(Client.t(), map()) :: Client.result(list())
  def list_templates(%Client{} = client, filters \\ %{}) do
    params = for {k, v} <- filters, v != nil, into: %{}, do: {k, v}
    opts = if map_size(params) > 0, do: [params: params], else: []

    case Client.get(client, "/community/templates", opts) do
      {:ok, body} -> {:ok, unwrap_list(body)}
      err -> err
    end
  end

  @doc """
  Get a community template by ID (GET `/community/templates/:template_id`).
  """
  @spec get_template(Client.t(), String.t()) :: Client.result(map())
  def get_template(%Client{} = client, template_id) when is_binary(template_id) do
    client
    |> Client.get("/community/templates/#{template_id}")
    |> unwrap()
  end

  @doc """
  Install a community template into the caller's tenant
  (POST `/community/templates/:template_id/install`).
  """
  @spec install_template(Client.t(), String.t(), map()) :: Client.result(map())
  def install_template(%Client{} = client, template_id, opts \\ %{})
      when is_binary(template_id) do
    body = for {k, v} <- opts, v != nil, into: %{}, do: {to_string(k), v}

    client
    |> Client.post("/community/templates/#{template_id}/install", body)
    |> unwrap()
  end

  @doc """
  Rate a community template 1-5 (POST `/community/templates/:template_id/rate`).
  """
  @spec rate_template(Client.t(), String.t(), 1..5, map()) :: Client.result(map())
  def rate_template(%Client{} = client, template_id, rating, opts \\ %{})
      when is_binary(template_id) and rating in 1..5 do
    body =
      opts
      |> Enum.reduce(%{"rating" => rating}, fn {k, v}, acc ->
        if v != nil, do: Map.put(acc, to_string(k), v), else: acc
      end)

    client
    |> Client.post("/community/templates/#{template_id}/rate", body)
    |> unwrap()
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap_list(%{"data" => list}) when is_list(list), do: list
  defp unwrap_list(%{"templates" => list}) when is_list(list), do: list
  defp unwrap_list(%{"agents" => list}) when is_list(list), do: list
  defp unwrap_list(%{"items" => list}) when is_list(list), do: list
  defp unwrap_list(list) when is_list(list), do: list
  defp unwrap_list(_), do: []

  defp unwrap({:ok, %{"data" => data}}), do: {:ok, data}
  defp unwrap({:ok, body}), do: {:ok, body}
  defp unwrap(err), do: err
end
