defmodule Miosa.ApiKeys do
  @moduledoc """
  API key management — programmatic CRUD for tenant API keys.

  The plaintext token is returned **only at creation time**. Store it
  immediately; the server only retains a hash.

  Mutating calls (create) send an `Idempotency-Key` header automatically.

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

      {:ok, result} = Miosa.ApiKeys.create(client, %{
        name: "ci-deploy",
        scopes: ["computers:read", "computers:write"]
      })

      # Store result["token"] immediately — it will not be shown again.

      {:ok, keys} = Miosa.ApiKeys.list(client)
      :ok = Miosa.ApiKeys.delete(client, result["id"])
  """

  alias Miosa.Client

  @doc """
  List API keys for the authenticated tenant.

  Note: The plaintext token is never returned by the list endpoint.
  Accepts optional filters as a keyword list or map (e.g. `:limit`, `:cursor`).
  """
  @spec list(Client.t(), keyword() | map()) :: Client.result(map())
  def list(client, filters \\ []) do
    query = filters |> normalize() |> build_query()
    Client.get(client, "/api-keys" <> query)
  end

  @doc """
  Create an API key.

  Required: `:name`. Optional: `:scopes` (list of scope strings), `:expires_at`,
  `:metadata`, `:idempotency_key`.

  The response contains a one-time plaintext `:token` (or `"key"`). Store it
  immediately; the server only keeps a hash.
  """
  @spec create(Client.t(), map()) :: Client.result(map())
  def create(client, attrs) when is_map(attrs) do
    idem = pop_idempotency(attrs)
    Client.post(client, "/api-keys", strip_nil(attrs), headers: [{"idempotency-key", idem}])
  end

  @doc "Revoke (delete) an API key by ID."
  @spec delete(Client.t(), String.t()) :: Client.result(map())
  def delete(client, key_id) when is_binary(key_id) do
    Client.delete(client, "/api-keys/" <> key_id)
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
