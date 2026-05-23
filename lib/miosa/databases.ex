defmodule Miosa.Databases do
  @moduledoc """
  Managed Postgres databases — CRUD, lifecycle, credentials, logs.

  All mutating calls send an `Idempotency-Key` header automatically.
  Supply `:idempotency_key` in `attrs` to use your own.

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

      {:ok, db} = Miosa.Databases.create(client, %{name: "my-db", plan: "starter"})
      {:ok, creds} = Miosa.Databases.credentials(client, db["id"])
      IO.puts(creds["url"])
  """

  alias Miosa.Client

  # ── List / Get / Create / Delete ────────────────────────────────────────────

  @doc """
  List databases for the authenticated tenant.

  Accepts optional filters as a keyword list or map (e.g. `:limit`, `:cursor`).
  """
  @spec list(Client.t(), keyword() | map()) :: Client.result(map())
  def list(client, filters \\ []) do
    query = filters |> normalize() |> build_query()
    Client.get(client, "/databases" <> query)
  end

  @doc "Fetch a database by ID."
  @spec get(Client.t(), String.t()) :: Client.result(map())
  def get(client, database_id) when is_binary(database_id) do
    Client.get(client, "/databases/" <> database_id)
  end

  @doc """
  Create a database.

  Required: `:name`. Optional: `:plan`, `:region`, and any other attrs accepted
  by the API. Pass `:idempotency_key` to supply your own key.
  """
  @spec create(Client.t(), map()) :: Client.result(map())
  def create(client, attrs) when is_map(attrs) do
    idem = pop_idempotency(attrs)
    Client.post(client, "/databases", strip_nil(attrs), headers: [{"idempotency-key", idem}])
  end

  @doc "Delete a database by ID."
  @spec delete(Client.t(), String.t()) :: Client.result(map())
  def delete(client, database_id) when is_binary(database_id) do
    Client.delete(client, "/databases/" <> database_id)
  end

  # ── Lifecycle ────────────────────────────────────────────────────────────────

  @doc "Start a stopped database."
  @spec start(Client.t(), String.t()) :: Client.result(map())
  def start(client, database_id) when is_binary(database_id) do
    idem = generate_idempotency_key()

    Client.post(client, "/databases/#{database_id}/start", nil,
      headers: [{"idempotency-key", idem}]
    )
  end

  @doc "Stop a running database."
  @spec stop(Client.t(), String.t()) :: Client.result(map())
  def stop(client, database_id) when is_binary(database_id) do
    idem = generate_idempotency_key()

    Client.post(client, "/databases/#{database_id}/stop", nil,
      headers: [{"idempotency-key", idem}]
    )
  end

  @doc "Restart a database."
  @spec restart(Client.t(), String.t()) :: Client.result(map())
  def restart(client, database_id) when is_binary(database_id) do
    idem = generate_idempotency_key()

    Client.post(client, "/databases/#{database_id}/restart", nil,
      headers: [{"idempotency-key", idem}]
    )
  end

  # ── Credentials + logs ──────────────────────────────────────────────────────

  @doc "Get connection credentials (URL, host, port, user, password) for a database."
  @spec credentials(Client.t(), String.t()) :: Client.result(map())
  def credentials(client, database_id) when is_binary(database_id) do
    Client.get(client, "/databases/#{database_id}/credentials")
  end

  @doc """
  Get recent logs for a database.

  Options:
    * `:lines` — Number of log lines to return.
    * `:since` — ISO 8601 timestamp to fetch logs since.
  """
  @spec logs(Client.t(), String.t(), keyword() | map()) :: Client.result(map())
  def logs(client, database_id, opts \\ []) when is_binary(database_id) do
    query = opts |> normalize() |> build_query()
    Client.get(client, "/databases/#{database_id}/logs" <> query)
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
