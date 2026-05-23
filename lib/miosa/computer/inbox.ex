defmodule Miosa.Computer.Inbox do
  @moduledoc """
  Per-computer inbox configuration for Optimal inbound-email routing.

  Maps to `GET /computers/:id/inbox` and `PATCH /computers/:id/inbox`.
  """

  alias Miosa.Client

  @doc """
  Fetch the current inbox configuration (GET `/computers/:computer_id/inbox`).
  """
  @spec get(Client.t(), String.t()) :: Client.result(map())
  def get(%Client{} = client, computer_id) when is_binary(computer_id) do
    client
    |> Client.get("/computers/#{computer_id}/inbox")
    |> unwrap()
  end

  @doc """
  Patch one or more inbox fields (PATCH `/computers/:computer_id/inbox`).

  Common fields: `alias`, `enabled`.
  """
  @spec update(Client.t(), String.t(), map()) :: Client.result(map())
  def update(%Client{} = client, computer_id, fields)
      when is_binary(computer_id) and is_map(fields) do
    body = for {k, v} <- fields, v != nil, into: %{}, do: {to_string(k), v}

    client
    |> Client.patch("/computers/#{computer_id}/inbox", body)
    |> unwrap()
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap({:ok, %{"data" => data}}), do: {:ok, data}
  defp unwrap({:ok, body}), do: {:ok, body}
  defp unwrap(err), do: err
end
