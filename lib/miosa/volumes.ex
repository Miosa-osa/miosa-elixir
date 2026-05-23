defmodule Miosa.Volumes do
  @moduledoc """
  Persistent block storage volumes that survive instance restarts.

  Volumes can be attached to computers to provide durable storage
  beyond the ephemeral rootfs.

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

      {:ok, vol} = Miosa.Volumes.create(client, %{name: "data", size_gb: 20})
      {:ok, vol} = Miosa.Volumes.get(client, vol["id"])
  """

  alias Miosa.Client

  @doc """
  List volumes for the authenticated tenant.

  Accepts optional filters as a keyword list or map (e.g. `:limit`, `:cursor`).
  """
  @spec list(Client.t(), keyword() | map()) :: Client.result(map())
  def list(client, filters \\ []) do
    query = filters |> normalize() |> build_query()
    Client.get(client, "/volumes" <> query)
  end

  @doc "Fetch a volume by ID."
  @spec get(Client.t(), String.t()) :: Client.result(map())
  def get(client, volume_id) when is_binary(volume_id) do
    Client.get(client, "/volumes/" <> volume_id)
  end

  @doc """
  Create a volume.

  Required: `:name`, `:size_gb`. Optional: `:region`, and any other attrs.
  Pass `:idempotency_key` to supply your own idempotency key.
  """
  @spec create(Client.t(), map()) :: Client.result(map())
  def create(client, attrs) when is_map(attrs) do
    idem = pop_idempotency(attrs)
    Client.post(client, "/volumes", strip_nil(attrs), headers: [{"idempotency-key", idem}])
  end

  @doc "Delete a volume by ID."
  @spec delete(Client.t(), String.t()) :: Client.result(map())
  def delete(client, volume_id) when is_binary(volume_id) do
    Client.delete(client, "/volumes/" <> volume_id)
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
