defmodule Miosa.Storage do
  @moduledoc """
  Managed S3-compatible object storage — buckets, objects, presigned URLs.

  Object keys are URL-encoded before inclusion in path segments.
  Mutating bucket operations send an `Idempotency-Key` header automatically.

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

      {:ok, bucket} = Miosa.Storage.create_bucket(client, %{name: "assets"})
      {:ok, result} = Miosa.Storage.presign(client, bucket["id"], %{
        key: "uploads/logo.png",
        operation: "put",
        expires_in_sec: 600
      })
      IO.puts(result["url"])
  """

  alias Miosa.Client

  # ── Buckets ──────────────────────────────────────────────────────────────────

  @doc "List all storage buckets for the authenticated tenant."
  @spec list_buckets(Client.t()) :: Client.result(map())
  def list_buckets(client) do
    Client.get(client, "/storage/buckets")
  end

  @doc """
  Create a storage bucket.

  Required: `:name`. Optional: `:region`, `:public`, and any other attrs.
  Pass `:idempotency_key` in `attrs` to supply your own idempotency key.
  """
  @spec create_bucket(Client.t(), map()) :: Client.result(map())
  def create_bucket(client, attrs) when is_map(attrs) do
    idem = pop_idempotency(attrs)

    Client.post(client, "/storage/buckets", strip_nil(attrs),
      headers: [{"idempotency-key", idem}]
    )
  end

  @doc "Fetch a bucket by ID."
  @spec get_bucket(Client.t(), String.t()) :: Client.result(map())
  def get_bucket(client, bucket_id) when is_binary(bucket_id) do
    Client.get(client, "/storage/buckets/" <> bucket_id)
  end

  @doc "Delete a bucket by ID."
  @spec delete_bucket(Client.t(), String.t()) :: Client.result(map())
  def delete_bucket(client, bucket_id) when is_binary(bucket_id) do
    Client.delete(client, "/storage/buckets/" <> bucket_id)
  end

  # ── Objects ──────────────────────────────────────────────────────────────────

  @doc """
  List objects in a bucket.

  Options:
    * `:prefix` — Filter by key prefix.
    * `:limit` — Max objects to return.
    * `:cursor` — Pagination cursor.
  """
  @spec list_objects(Client.t(), String.t(), keyword() | map()) :: Client.result(map())
  def list_objects(client, bucket_id, opts \\ []) when is_binary(bucket_id) do
    query = opts |> normalize() |> build_query()
    Client.get(client, "/storage/buckets/#{bucket_id}/objects" <> query)
  end

  @doc """
  Upload bytes to an object key in a bucket.

  `content_type` defaults to `"application/octet-stream"`.
  The key is URL-encoded before being placed in the path.
  """
  @spec put_object(Client.t(), String.t(), String.t(), binary(), keyword()) ::
          Client.result(map())
  def put_object(client, bucket_id, key, content, opts \\ [])
      when is_binary(bucket_id) and is_binary(key) and is_binary(content) do
    content_type = Keyword.get(opts, :content_type, "application/octet-stream")
    encoded_key = URI.encode(key)

    Client.put(
      client,
      "/storage/buckets/#{bucket_id}/objects/#{encoded_key}",
      nil,
      headers: [{"content-type", content_type}],
      body: content
    )
  end

  @doc """
  Download the raw bytes of an object.

  The key is URL-encoded before being placed in the path.
  """
  @spec get_object(Client.t(), String.t(), String.t()) :: Client.result(binary())
  def get_object(client, bucket_id, key)
      when is_binary(bucket_id) and is_binary(key) do
    encoded_key = URI.encode(key)
    Client.get_binary(client, "/storage/buckets/#{bucket_id}/objects/#{encoded_key}")
  end

  @doc "Delete an object from a bucket. The key is URL-encoded automatically."
  @spec delete_object(Client.t(), String.t(), String.t()) :: Client.result(map())
  def delete_object(client, bucket_id, key)
      when is_binary(bucket_id) and is_binary(key) do
    encoded_key = URI.encode(key)
    Client.delete(client, "/storage/buckets/#{bucket_id}/objects/#{encoded_key}")
  end

  # ── Presigned URLs ───────────────────────────────────────────────────────────

  @doc """
  Mint a presigned URL for direct browser upload or download.

  Required `attrs`:
    * `:key` — Object key.

  Optional `attrs`:
    * `:operation` — `"get"` (default) or `"put"`.
    * `:expires_in_sec` — Expiry in seconds. Defaults to `300`.
    * `:content_type` — Required for `"put"` uploads.
  """
  @spec presign(Client.t(), String.t(), map()) :: Client.result(map())
  def presign(client, bucket_id, attrs) when is_binary(bucket_id) and is_map(attrs) do
    body =
      attrs
      |> Map.put_new(:operation, "get")
      |> Map.put_new(:expires_in_sec, 300)
      |> strip_nil()

    Client.post(client, "/storage/buckets/#{bucket_id}/presign", body)
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
