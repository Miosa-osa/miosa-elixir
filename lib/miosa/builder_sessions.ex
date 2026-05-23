defmodule Miosa.BuilderSessions do
  @moduledoc """
  Builder UI session metadata — durable, cross-device Builder state.

  Routes live under `/api/v1/builder/sessions/` and accept `msk_*` API
  keys or JWT. Builder sessions are `optimal_sessions` with
  `resource_type = "sandbox"` and `vm_context.template_type = "miosa-sandbox"`.
  """

  alias Miosa.Client

  @doc """
  List builder sessions (GET `/builder/sessions`).

  ## Options

    * `:limit` — Maximum sessions to return. Defaults to `50`.
    * Any extra key is forwarded as a query param.
  """
  @spec list(Client.t(), Keyword.t()) :: Client.result(list())
  def list(%Client{} = client, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    params =
      opts
      |> Keyword.delete(:limit)
      |> Enum.reduce(%{"limit" => limit}, fn {k, v}, acc ->
        if v != nil, do: Map.put(acc, to_string(k), v), else: acc
      end)

    case Client.get(client, "/builder/sessions", params: params) do
      {:ok, body} -> {:ok, unwrap_list(body)}
      err -> err
    end
  end

  @doc """
  Get a single builder session by ID.

  Falls back to filtering `list/2` since the platform router only exposes
  index + title-update + delete.
  """
  @spec get(Client.t(), String.t()) :: Client.result(map() | nil)
  def get(%Client{} = client, session_id) when is_binary(session_id) do
    case list(client) do
      {:ok, sessions} ->
        found = Enum.find(sessions, fn s -> Map.get(s, "id") == session_id end)
        {:ok, found}

      err ->
        err
    end
  end

  @doc """
  Update the title of a builder session
  (PATCH `/builder/sessions/:session_id/title`).
  """
  @spec update_title(Client.t(), String.t(), String.t()) :: Client.result(map())
  def update_title(%Client{} = client, session_id, title)
      when is_binary(session_id) and is_binary(title) do
    client
    |> Client.patch("/builder/sessions/#{session_id}/title", %{"title" => title})
    |> unwrap()
  end

  @doc """
  Delete a builder session (DELETE `/builder/sessions/:session_id`).
  """
  @spec delete(Client.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def delete(%Client{} = client, session_id) when is_binary(session_id) do
    case Client.delete(client, "/builder/sessions/#{session_id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap_list(%{"data" => list}) when is_list(list), do: list
  defp unwrap_list(%{"sessions" => list}) when is_list(list), do: list
  defp unwrap_list(%{"items" => list}) when is_list(list), do: list
  defp unwrap_list(list) when is_list(list), do: list
  defp unwrap_list(_), do: []

  defp unwrap({:ok, %{"data" => data}}), do: {:ok, data}
  defp unwrap({:ok, body}), do: {:ok, body}
  defp unwrap(err), do: err
end
