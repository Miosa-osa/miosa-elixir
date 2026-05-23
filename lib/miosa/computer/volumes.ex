defmodule Miosa.Computer.Volumes do
  @moduledoc """
  Per-computer volume attachment management.

    * `GET    /computers/:id/volumes`          — list/2
    * `POST   /computers/:id/volumes`          — attach/4
    * `DELETE /computers/:id/volumes/:aid`     — detach/3
  """

  alias Miosa.Client

  @doc """
  List volume attachments for a computer
  (GET `/computers/:computer_id/volumes`).
  """
  @spec list(Client.t(), String.t()) :: Client.result(list())
  def list(%Client{} = client, computer_id) when is_binary(computer_id) do
    case Client.get(client, "/computers/#{computer_id}/volumes") do
      {:ok, body} -> {:ok, unwrap_list(body)}
      err -> err
    end
  end

  @doc """
  Attach a volume at `mount_path` inside the VM
  (POST `/computers/:computer_id/volumes`).
  """
  @spec attach(Client.t(), String.t(), String.t(), String.t()) :: Client.result(map())
  def attach(%Client{} = client, computer_id, volume_id, mount_path)
      when is_binary(computer_id) and is_binary(volume_id) and is_binary(mount_path) do
    body = %{"volume_id" => volume_id, "mount_path" => mount_path}

    client
    |> Client.post("/computers/#{computer_id}/volumes", body)
    |> unwrap()
  end

  @doc """
  Detach a volume attachment by attachment ID
  (DELETE `/computers/:computer_id/volumes/:attachment_id`).
  """
  @spec detach(Client.t(), String.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def detach(%Client{} = client, computer_id, attachment_id)
      when is_binary(computer_id) and is_binary(attachment_id) do
    case Client.delete(client, "/computers/#{computer_id}/volumes/#{attachment_id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap_list(%{"data" => list}) when is_list(list), do: list
  defp unwrap_list(%{"attachments" => list}) when is_list(list), do: list
  defp unwrap_list(%{"volumes" => list}) when is_list(list), do: list
  defp unwrap_list(%{"items" => list}) when is_list(list), do: list
  defp unwrap_list(list) when is_list(list), do: list
  defp unwrap_list(_), do: []

  defp unwrap({:ok, %{"data" => data}}), do: {:ok, data}
  defp unwrap({:ok, body}), do: {:ok, body}
  defp unwrap(err), do: err
end
