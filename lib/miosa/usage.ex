defmodule Miosa.Usage do
  @moduledoc """
  Usage — current period summary, per-session metering, and report queries.

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

      {:ok, summary} = Miosa.Usage.current(client)
      {:ok, sessions} = Miosa.Usage.sessions(client, %{limit: 100})
  """

  alias Miosa.Client

  @doc "Get the current period usage summary."
  @spec current(Client.t()) :: Client.result(map())
  def current(client) do
    Client.get(client, "/usage/summary")
  end

  @doc """
  List per-session metering events.

  Accepts optional filters as a keyword list or map (e.g. `:limit`, `:cursor`,
  `:computer_id`).
  """
  @spec sessions(Client.t(), keyword() | map()) :: Client.result(map())
  def sessions(client, filters \\ []) do
    query = filters |> normalize() |> build_query()
    Client.get(client, "/usage/sessions" <> query)
  end

  @doc """
  Get a usage report for a period.

  Options: `:period_start` and `:period_end` (ISO 8601 strings), plus any
  additional filters accepted by the API.
  """
  @spec report(Client.t(), keyword() | map()) :: Client.result(map())
  def report(client, filters \\ []) do
    query = filters |> normalize() |> build_query()
    Client.get(client, "/usage/summary" <> query)
  end

  @doc """
  Rollup usage grouped by `external_user_id`, `external_project_id`, or
  `workspace_id`.

  GET `/api/v1/usage?group_by=<group>&period=<period>`

  ## Options
    * `:group_by` — `"external_user_id"` (default), `"external_project_id"`,
      or `"workspace_id"`.
    * `:period`   — `"7d"`, `"30d"`, `"month-to-date"`, or a map
      `%{start: iso, end: iso}`.
    * `:external_user_id` — filter to a single user.

  Returns `{:ok, %{"period_start" => _, "period_end" => _, "results" => [...]}}`.
  """
  @spec get(Client.t(), keyword() | map()) :: Client.result(map())
  def get(client, opts \\ []) do
    params =
      opts
      |> normalize()
      |> then(fn m ->
        case Map.get(m, :period) || Map.get(m, "period") do
          %{start: s, end: e} ->
            m
            |> Map.delete(:period)
            |> Map.delete("period")
            |> Map.put("start", s)
            |> Map.put("end", e)

          _ ->
            m
        end
      end)

    query = build_query(params)

    case Client.get(client, "/usage" <> query) do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, body} -> {:ok, body}
      err -> err
    end
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
