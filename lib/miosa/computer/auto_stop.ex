defmodule Miosa.Computer.AutoStop do
  @moduledoc """
  Read and update idle-timeout config for a computer.

  Maps to `GET /computers/:id/auto-stop` and `PATCH /computers/:id/auto-stop`.
  """

  alias Miosa.Client

  @doc """
  Return the current auto-stop configuration
  (GET `/computers/:computer_id/auto-stop`).
  """
  @spec get(Client.t(), String.t()) :: Client.result(map())
  def get(%Client{} = client, computer_id) when is_binary(computer_id) do
    client
    |> Client.get("/computers/#{computer_id}/auto-stop")
    |> unwrap()
  end

  @doc """
  Set the idle timeout in seconds (PATCH `/computers/:computer_id/auto-stop`).

  Pass `0` to disable auto-stop entirely.
  """
  @spec update(Client.t(), String.t(), non_neg_integer()) :: Client.result(map())
  def update(%Client{} = client, computer_id, seconds)
      when is_binary(computer_id) and is_integer(seconds) and seconds >= 0 do
    client
    |> Client.patch("/computers/#{computer_id}/auto-stop", %{"seconds" => seconds})
    |> unwrap()
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap({:ok, %{"data" => data}}), do: {:ok, data}
  defp unwrap({:ok, body}), do: {:ok, body}
  defp unwrap(err), do: err
end
