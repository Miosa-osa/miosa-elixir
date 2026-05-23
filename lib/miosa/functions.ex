defmodule Miosa.Functions do
  @moduledoc """
  Edge functions — serverless, request-driven code that runs close to the user.

  Functions support full CRUD and can be invoked synchronously.
  Mutating calls send an `Idempotency-Key` header automatically.

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

      {:ok, fn_} = Miosa.Functions.create(client, %{
        name: "resize-image",
        runtime: "node18",
        source: "export default (req) => new Response('ok')"
      })

      {:ok, result} = Miosa.Functions.invoke(client, fn_["id"], %{
        payload: %{url: "https://example.com/logo.png"}
      })
  """

  alias Miosa.Client

  # ── CRUD ─────────────────────────────────────────────────────────────────────

  @doc """
  List functions for the authenticated tenant.

  Accepts optional filters as a keyword list or map (e.g. `:limit`, `:cursor`).
  """
  @spec list(Client.t(), keyword() | map()) :: Client.result(map())
  def list(client, filters \\ []) do
    query = filters |> normalize() |> build_query()
    Client.get(client, "/functions" <> query)
  end

  @doc "Fetch a function by ID."
  @spec get(Client.t(), String.t()) :: Client.result(map())
  def get(client, function_id) when is_binary(function_id) do
    Client.get(client, "/functions/" <> function_id)
  end

  @doc """
  Create a function.

  Required: `:name`. Optional: `:runtime`, `:source`, `:env`, `:metadata`,
  `:idempotency_key`.
  """
  @spec create(Client.t(), map()) :: Client.result(map())
  def create(client, attrs) when is_map(attrs) do
    idem = pop_idempotency(attrs)
    Client.post(client, "/functions", strip_nil(attrs), headers: [{"idempotency-key", idem}])
  end

  @doc """
  Update a function.

  Pass any fields to update; nil values are dropped.
  """
  @spec update(Client.t(), String.t(), map()) :: Client.result(map())
  def update(client, function_id, attrs) when is_binary(function_id) and is_map(attrs) do
    Client.patch(client, "/functions/" <> function_id, strip_nil(attrs))
  end

  @doc "Delete a function by ID."
  @spec delete(Client.t(), String.t()) :: Client.result(map())
  def delete(client, function_id) when is_binary(function_id) do
    Client.delete(client, "/functions/" <> function_id)
  end

  # ── Invoke ───────────────────────────────────────────────────────────────────

  @doc """
  Invoke a function synchronously.

  Optional `opts`:
    * `:payload` — Map to send as the request body.
    * `:idempotency_key` — Idempotency key for the invocation.
  """
  @spec invoke(Client.t(), String.t(), keyword() | map()) :: Client.result(map())
  def invoke(client, function_id, opts \\ []) when is_binary(function_id) do
    opts_map = normalize(opts)
    payload = Map.get(opts_map, :payload) || Map.get(opts_map, "payload") || %{}
    idem = pop_idempotency(opts_map)

    Client.post(client, "/functions/#{function_id}/invoke", payload,
      headers: [{"idempotency-key", idem}]
    )
  end

  # ── Helpers ──────────────────────────────────────────────────────────────────

  defp pop_idempotency(attrs) do
    cond do
      is_map(attrs) -> Map.get(attrs, :idempotency_key) || Map.get(attrs, "idempotency_key")
      Keyword.keyword?(attrs) -> Keyword.get(attrs, :idempotency_key)
      true -> nil
    end || generate_idempotency_key()
  end

  defp generate_idempotency_key do
    16 |> :crypto.strong_rand_bytes() |> Base.encode16(case: :lower)
  end

  defp strip_nil(map) when is_map(map) do
    map
    |> Map.delete(:idempotency_key)
    |> Map.delete("idempotency_key")
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

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
