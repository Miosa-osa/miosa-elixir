defmodule Miosa.Computers do
  @moduledoc """
  Manage MIOSA computers (VM workspaces).

  Computers are the core resource: isolated Linux VMs with a full desktop
  environment, terminal access, and an OSA agent running inside each one.

  ## Example

      client = Miosa.client("msk_u_...")

      {:ok, computer} = Miosa.Computers.create(client, %{
        name: "my-agent-workspace",
        template_type: "miosa-desktop",
        size: "small"
      })

      {:ok, computers} = Miosa.Computers.list(client)
      {:ok, computer} = Miosa.Computers.get(client, computer.id)
      :ok = Miosa.Computers.delete(client, computer.id)

  """

  alias Miosa.{Client, Types}

  @type create_params :: %{
          optional(:name) => String.t(),
          optional(:template_type) => String.t(),
          optional(:size) => String.t(),
          optional(:metadata) => map()
        }

  @doc """
  Creates a new computer.

  The computer starts in `:creating` status. Use `Miosa.Computer.start/2` to
  boot it, or poll `get/2` until the status becomes `:running`.

  ## Params

    * `:name` — Display name (optional, auto-generated if omitted).
    * `:template_type` — Template to use. Defaults to `"miosa-desktop"`.
    * `:size` — VM size: `"small"` (default), `"medium"`, `"large"`.
    * `:metadata` — Arbitrary key-value map stored with the computer.

  """
  @spec create(Client.t(), create_params()) :: Client.result(Types.Computer.t())
  def create(%Client{} = client, params \\ %{}) do
    client
    |> Client.post("/computers", stringify_keys(params))
    |> unwrap_computer()
  end

  @doc """
  Lists all computers for the authenticated tenant.

  Returns a list of `Miosa.Types.Computer` structs ordered by creation time
  (newest first).
  """
  @spec list(Client.t()) :: Client.result([Types.Computer.t()])
  def list(%Client{} = client) do
    case Client.get(client, "/computers") do
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

  @doc """
  Fetches a single computer by ID.
  """
  @spec get(Client.t(), String.t()) :: Client.result(Types.Computer.t())
  def get(%Client{} = client, id) when is_binary(id) do
    client
    |> Client.get("/computers/#{id}")
    |> unwrap_computer()
  end

  @doc """
  Deletes a computer and destroys all associated resources.

  The computer must be stopped before deletion, or pass `force: true` to
  force destroy a running computer (data will be lost).
  """
  @spec delete(Client.t(), String.t(), keyword()) :: :ok | {:error, Miosa.Error.t()}
  def delete(%Client{} = client, id, opts \\ []) when is_binary(id) do
    params = if Keyword.get(opts, :force, false), do: %{force: true}, else: %{}

    client
    |> Client.delete("/computers/#{id}", params: params)
    |> to_ok()
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap_computer({:ok, body}) do
    computer = body |> get_resource() |> Types.Computer.from_map()
    {:ok, computer}
  end

  defp unwrap_computer({:error, _} = err), do: err

  defp to_ok({:ok, _}), do: :ok
  defp to_ok({:error, _} = err), do: err

  # The API may return the resource at the top level or under a "data" key
  defp get_resource(%{"data" => data}) when is_map(data), do: data
  defp get_resource(%{"computer" => data}) when is_map(data), do: data
  defp get_resource(map) when is_map(map), do: map

  defp get_list(%{"data" => list}) when is_list(list), do: list
  defp get_list(%{"computers" => list}) when is_list(list), do: list
  defp get_list(list) when is_list(list), do: list
  defp get_list(_), do: []

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end
end
