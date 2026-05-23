defmodule Miosa.Computer.Metrics do
  @moduledoc """
  Time-series RAM/CPU/credit metrics for a computer.

  Maps to `GET /computers/:id/metrics`.
  """

  alias Miosa.Client

  @doc """
  Return metric series for a time window
  (GET `/computers/:computer_id/metrics`).

  `window` is a duration string such as `"1h"`, `"24h"`, or `"7d"`.
  Defaults to `"1h"`.
  """
  @spec get(Client.t(), String.t(), String.t()) :: Client.result(map())
  def get(%Client{} = client, computer_id, window \\ "1h")
      when is_binary(computer_id) and is_binary(window) do
    client
    |> Client.get("/computers/#{computer_id}/metrics", params: %{"window" => window})
    |> unwrap()
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap({:ok, %{"data" => data}}), do: {:ok, data}
  defp unwrap({:ok, body}), do: {:ok, body}
  defp unwrap(err), do: err
end
