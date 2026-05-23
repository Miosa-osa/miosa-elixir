defmodule Miosa.SnapshotsStandalone do
  @moduledoc """
  Fleet-wide snapshot index for admin callers.

  Routes live under `/api/v1/admin/snapshots/` and require an admin
  credential. Per-computer snapshots remain nested under the computer's
  checkpoint resource. This module exposes the fleet-wide read-only index
  used by the platform admin dashboard.
  """

  alias Miosa.Client

  @doc """
  List all snapshots fleet-wide (GET `/admin/snapshots`).

  Accepts optional filter params (e.g. `%{computer_id: "..."}`, `%{status: "ready"}`).
  """
  @spec list(Client.t(), map()) :: Client.result(list())
  def list(%Client{} = client, filters \\ %{}) do
    params = for {k, v} <- filters, v != nil, into: %{}, do: {k, v}
    opts = if map_size(params) > 0, do: [params: params], else: []

    case Client.get(client, "/admin/snapshots", opts) do
      {:ok, body} -> {:ok, unwrap_list(body)}
      err -> err
    end
  end

  @doc """
  Get a snapshot by ID (GET `/admin/snapshots/:snapshot_id`).
  """
  @spec get(Client.t(), String.t()) :: Client.result(map())
  def get(%Client{} = client, snapshot_id) when is_binary(snapshot_id) do
    client
    |> Client.get("/admin/snapshots/#{snapshot_id}")
    |> unwrap()
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap_list(%{"data" => list}) when is_list(list), do: list
  defp unwrap_list(%{"snapshots" => list}) when is_list(list), do: list
  defp unwrap_list(%{"items" => list}) when is_list(list), do: list
  defp unwrap_list(list) when is_list(list), do: list
  defp unwrap_list(_), do: []

  defp unwrap({:ok, %{"data" => data}}), do: {:ok, data}
  defp unwrap({:ok, %{"snapshots" => data}}), do: {:ok, data}
  defp unwrap({:ok, body}), do: {:ok, body}
  defp unwrap(err), do: err
end
