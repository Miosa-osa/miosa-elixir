defmodule Miosa.Models do
  @moduledoc """
  List available LLM models routed through the MIOSA intelligence gateway.

  Routes live under `/api/v1/intelligence/` and require an `mki_*`
  intelligence key or a JWT (dashboard users).
  """

  alias Miosa.Client

  @doc """
  List all models available to the calling tenant (OpenAI-compatible shape).

  Accepts optional filter params (e.g. `provider:`, `type:`).
  """
  @spec list(Client.t(), map()) :: Client.result(list())
  def list(%Client{} = client, filters \\ %{}) do
    params = for {k, v} <- filters, v != nil, into: %{}, do: {k, v}
    opts = if map_size(params) > 0, do: [params: params], else: []

    case Client.get(client, "/intelligence/models", opts) do
      {:ok, body} -> {:ok, unwrap_list(body)}
      err -> err
    end
  end

  @doc """
  Get a single model by id, filtering the list response client-side.

  Returns `{:ok, model}` or `{:ok, nil}` if not found.
  """
  @spec get(Client.t(), String.t()) :: Client.result(map() | nil)
  def get(%Client{} = client, model_id) when is_binary(model_id) do
    case list(client) do
      {:ok, models} ->
        found = Enum.find(models, fn m -> Map.get(m, "id") == model_id end)
        {:ok, found}

      err ->
        err
    end
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap_list(%{"data" => list}) when is_list(list), do: list
  defp unwrap_list(%{"models" => list}) when is_list(list), do: list
  defp unwrap_list(%{"items" => list}) when is_list(list), do: list
  defp unwrap_list(list) when is_list(list), do: list
  defp unwrap_list(_), do: []
end
