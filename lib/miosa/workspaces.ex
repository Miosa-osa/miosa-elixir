defmodule Miosa.Workspaces do
  @moduledoc """
  Manage MIOSA workspaces.

  A workspace groups one or more computers under a shared project boundary.
  Workspaces are identified by an ID and carry a display name and optional
  metadata. Every computer belongs to exactly one workspace.

  ## Example

      client = Miosa.client("msk_u_...")

      {:ok, ws} = Miosa.Workspaces.create(client, %{name: "my-project"})
      {:ok, workspaces} = Miosa.Workspaces.list(client)
      {:ok, ws} = Miosa.Workspaces.get(client, ws.id)
      {:ok, ws} = Miosa.Workspaces.update(client, ws.id, %{name: "renamed"})
      {:ok, computers} = Miosa.Workspaces.list_computers(client, ws.id)
      :ok = Miosa.Workspaces.delete(client, ws.id)

  """

  alias Miosa.{Client, Types}

  @type create_params :: %{
          required(:name) => String.t(),
          optional(:metadata) => map()
        }

  @type update_params :: %{
          optional(:name) => String.t(),
          optional(:metadata) => map()
        }

  @doc """
  Creates a new workspace.

  ## Params

    * `:name` — Required. Display name for the workspace.
    * `:metadata` — Optional. Arbitrary key-value map.

  """
  @spec create(Client.t(), create_params()) :: Client.result(Types.Workspace.t())
  def create(%Client{} = client, params) when is_map(params) do
    client
    |> Client.post("/workspaces", stringify_keys(params))
    |> unwrap_workspace()
  end

  @doc """
  Lists all workspaces for the authenticated tenant.
  """
  @spec list(Client.t()) :: Client.result([Types.Workspace.t()])
  def list(%Client{} = client) do
    case Client.get(client, "/workspaces") do
      {:ok, body} ->
        workspaces =
          body
          |> get_list()
          |> Enum.map(&Types.Workspace.from_map/1)

        {:ok, workspaces}

      {:error, _} = err ->
        err
    end
  end

  @doc """
  Fetches a single workspace by ID.
  """
  @spec get(Client.t(), String.t()) :: Client.result(Types.Workspace.t())
  def get(%Client{} = client, id) when is_binary(id) do
    client
    |> Client.get("/workspaces/#{id}")
    |> unwrap_workspace()
  end

  @doc """
  Updates a workspace's attributes.

  Only the supplied fields are updated (PATCH semantics).
  """
  @spec update(Client.t(), String.t(), update_params()) :: Client.result(Types.Workspace.t())
  def update(%Client{} = client, id, params) when is_binary(id) and is_map(params) do
    client
    |> Client.patch("/workspaces/#{id}", stringify_keys(params))
    |> unwrap_workspace()
  end

  @doc """
  Deletes a workspace.

  All computers in the workspace must be stopped or destroyed before deletion,
  or the API will return a 409 conflict.
  """
  @spec delete(Client.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def delete(%Client{} = client, id) when is_binary(id) do
    client
    |> Client.delete("/workspaces/#{id}")
    |> to_ok()
  end

  @doc """
  Lists all computers belonging to a workspace.
  """
  @spec list_computers(Client.t(), String.t()) :: Client.result([Types.Computer.t()])
  def list_computers(%Client{} = client, workspace_id) when is_binary(workspace_id) do
    case Client.get(client, "/workspaces/#{workspace_id}/computers") do
      {:ok, body} ->
        computers =
          body
          |> get_list()
          |> Enum.map(&Types.Computer.from_map/1)

        {:ok, computers}

      {:error, _} = err ->
        err
    end
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap_workspace({:ok, body}) do
    ws = body |> get_resource() |> Types.Workspace.from_map()
    {:ok, ws}
  end

  defp unwrap_workspace({:error, _} = err), do: err

  defp to_ok({:ok, _}), do: :ok
  defp to_ok({:error, _} = err), do: err

  defp get_resource(%{"data" => data}) when is_map(data), do: data
  defp get_resource(%{"workspace" => data}) when is_map(data), do: data
  defp get_resource(map) when is_map(map), do: map

  defp get_list(%{"data" => list}) when is_list(list), do: list
  defp get_list(%{"workspaces" => list}) when is_list(list), do: list
  defp get_list(%{"computers" => list}) when is_list(list), do: list
  defp get_list(list) when is_list(list), do: list
  defp get_list(_), do: []

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end
end
