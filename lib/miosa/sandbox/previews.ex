defmodule Miosa.Sandbox.Previews do
  @moduledoc """
  Preview URL management for a sandbox.

  Wraps `/sandboxes/:id/previews/*` — list, create, get, delete,
  share (mint token), and revoke share tokens.
  """

  alias Miosa.Client

  @doc """
  List preview records for a sandbox (GET `/sandboxes/:sandbox_id/previews`).
  """
  @spec list(Client.t(), String.t()) :: Client.result(list())
  def list(%Client{} = client, sandbox_id) when is_binary(sandbox_id) do
    case Client.get(client, "/sandboxes/#{sandbox_id}/previews") do
      {:ok, body} -> {:ok, unwrap_list(body)}
      err -> err
    end
  end

  @doc """
  Create a new preview for a port (POST `/sandboxes/:sandbox_id/previews`).

  `port` is required. Additional opts are merged into the body.
  """
  @spec create(Client.t(), String.t(), pos_integer(), map()) :: Client.result(map())
  def create(%Client{} = client, sandbox_id, port, opts \\ %{})
      when is_binary(sandbox_id) and is_integer(port) do
    body =
      opts
      |> Enum.reduce(%{"port" => port}, fn {k, v}, acc ->
        if v != nil, do: Map.put(acc, to_string(k), v), else: acc
      end)

    client
    |> Client.post("/sandboxes/#{sandbox_id}/previews", body)
    |> unwrap()
  end

  @doc """
  Get a preview by ID (GET `/sandboxes/:sandbox_id/previews/:preview_id`).
  """
  @spec get(Client.t(), String.t(), String.t()) :: Client.result(map())
  def get(%Client{} = client, sandbox_id, preview_id)
      when is_binary(sandbox_id) and is_binary(preview_id) do
    client
    |> Client.get("/sandboxes/#{sandbox_id}/previews/#{preview_id}")
    |> unwrap()
  end

  @doc """
  Delete a preview (DELETE `/sandboxes/:sandbox_id/previews/:preview_id`).
  """
  @spec delete(Client.t(), String.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def delete(%Client{} = client, sandbox_id, preview_id)
      when is_binary(sandbox_id) and is_binary(preview_id) do
    case Client.delete(client, "/sandboxes/#{sandbox_id}/previews/#{preview_id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @doc """
  Mint a share token for a preview
  (POST `/sandboxes/:sandbox_id/previews/:preview_id/share`).

  `expires_in_sec` defaults to `3600` (one hour).
  """
  @spec share(Client.t(), String.t(), String.t(), pos_integer()) :: Client.result(map())
  def share(%Client{} = client, sandbox_id, preview_id, expires_in_sec \\ 3600)
      when is_binary(sandbox_id) and is_binary(preview_id) and is_integer(expires_in_sec) do
    body = %{"expires_in_sec" => expires_in_sec}

    client
    |> Client.post("/sandboxes/#{sandbox_id}/previews/#{preview_id}/share", body)
    |> unwrap()
  end

  @doc """
  Invalidate every share token for a preview
  (DELETE `/sandboxes/:sandbox_id/previews/:preview_id/share`).
  """
  @spec revoke_share(Client.t(), String.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def revoke_share(%Client{} = client, sandbox_id, preview_id)
      when is_binary(sandbox_id) and is_binary(preview_id) do
    case Client.delete(client, "/sandboxes/#{sandbox_id}/previews/#{preview_id}/share") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap_list(list) when is_list(list), do: list
  defp unwrap_list(%{"data" => list}) when is_list(list), do: list
  defp unwrap_list(%{"previews" => list}) when is_list(list), do: list
  defp unwrap_list(%{"items" => list}) when is_list(list), do: list
  defp unwrap_list(_), do: []

  defp unwrap({:ok, %{"data" => data}}), do: {:ok, data}
  defp unwrap({:ok, body}), do: {:ok, body}
  defp unwrap(err), do: err
end
