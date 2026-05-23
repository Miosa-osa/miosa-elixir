defmodule Miosa.AuditLog do
  @moduledoc """
  Audit log — admin-scoped event stream.

  Requires an admin (`msk_a_` / `msk_p_`) key.

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_ADMIN_KEY"))

      {:ok, events} = Miosa.AuditLog.list(client)
      {:ok, filtered} = Miosa.AuditLog.list(client, %{action: "computer.create", limit: 50})
  """

  alias Miosa.Client

  @doc """
  List audit-log events.

  Accepts optional filters as a keyword list or map (e.g. `:action`, `:limit`,
  `:cursor`, `:since`).
  """
  @spec list(Client.t(), keyword() | map()) :: Client.result(map())
  def list(client, filters \\ []) do
    query = filters |> normalize() |> build_query()
    Client.get(client, "/audit-log" <> query)
  end

  # ── Helpers ───────────────────────────────────────────────────────────────────

  defp normalize(filters) when is_list(filters), do: Map.new(filters)
  defp normalize(filters) when is_map(filters), do: filters

  defp build_query(filters) when filters == %{}, do: ""

  defp build_query(filters) do
    "?" <>
      (filters
       |> Enum.reject(fn {_k, v} -> is_nil(v) end)
       |> Enum.map(fn {k, v} -> "#{k}=#{URI.encode_www_form(to_string(v))}" end)
       |> Enum.join("&"))
  end
end
