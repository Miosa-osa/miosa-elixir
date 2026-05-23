defmodule Miosa.Computer.Ports do
  @moduledoc """
  Per-port visibility control for a computer.

    * `GET    /computers/:id/ports`          — list/2
    * `POST   /computers/:id/ports`          — create/3
    * `PATCH  /computers/:id/ports/:port`    — update/4
    * `DELETE /computers/:id/ports/:port`    — delete/3

  The backend does not expose a single-port GET; `get/3` filters
  the list response client-side.
  """

  alias Miosa.Client

  @doc """
  List all exposed ports (GET `/computers/:computer_id/ports`).
  """
  @spec list(Client.t(), String.t()) :: Client.result(list())
  def list(%Client{} = client, computer_id) when is_binary(computer_id) do
    case Client.get(client, "/computers/#{computer_id}/ports") do
      {:ok, body} -> {:ok, unwrap_list(body)}
      err -> err
    end
  end

  @doc """
  Return the port record for `port`, or `{:ok, nil}` if not exposed.

  Filters `list/2` client-side.
  """
  @spec get(Client.t(), String.t(), pos_integer()) :: Client.result(map() | nil)
  def get(%Client{} = client, computer_id, port)
      when is_binary(computer_id) and is_integer(port) do
    case list(client, computer_id) do
      {:ok, ports} ->
        found = Enum.find(ports, fn p -> to_int(Map.get(p, "port")) == port end)
        {:ok, found}

      err ->
        err
    end
  end

  @doc """
  Expose a port with the given visibility options
  (POST `/computers/:computer_id/ports`).
  """
  @spec create(Client.t(), String.t(), pos_integer(), map()) :: Client.result(map())
  def create(%Client{} = client, computer_id, port, opts \\ %{})
      when is_binary(computer_id) and is_integer(port) do
    body =
      opts
      |> Enum.reduce(%{"port" => port}, fn {k, v}, acc ->
        if v != nil, do: Map.put(acc, to_string(k), v), else: acc
      end)

    client
    |> Client.post("/computers/#{computer_id}/ports", body)
    |> unwrap()
  end

  @doc """
  Patch visibility/auth options for a port
  (PATCH `/computers/:computer_id/ports/:port`).
  """
  @spec update(Client.t(), String.t(), pos_integer(), map()) :: Client.result(map())
  def update(%Client{} = client, computer_id, port, opts)
      when is_binary(computer_id) and is_integer(port) and is_map(opts) do
    body = for {k, v} <- opts, v != nil, into: %{}, do: {to_string(k), v}

    client
    |> Client.patch("/computers/#{computer_id}/ports/#{port}", body)
    |> unwrap()
  end

  @doc """
  Stop exposing a port (DELETE `/computers/:computer_id/ports/:port`).
  """
  @spec delete(Client.t(), String.t(), pos_integer()) :: :ok | {:error, Miosa.Error.t()}
  def delete(%Client{} = client, computer_id, port)
      when is_binary(computer_id) and is_integer(port) do
    case Client.delete(client, "/computers/#{computer_id}/ports/#{port}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap_list(%{"data" => list}) when is_list(list), do: list
  defp unwrap_list(%{"ports" => list}) when is_list(list), do: list
  defp unwrap_list(%{"items" => list}) when is_list(list), do: list
  defp unwrap_list(list) when is_list(list), do: list
  defp unwrap_list(_), do: []

  defp unwrap({:ok, %{"data" => data}}), do: {:ok, data}
  defp unwrap({:ok, body}), do: {:ok, body}
  defp unwrap(err), do: err

  defp to_int(v) when is_integer(v), do: v
  defp to_int(v) when is_binary(v), do: String.to_integer(v)
  defp to_int(_), do: -1
end
