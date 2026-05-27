# `Miosa.Storage`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/storage.ex#L1)

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

# `create_bucket`

```elixir
@spec create_bucket(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Create a storage bucket.

Required: `:name`. Optional: `:region`, `:public`, and any other attrs.
Pass `:idempotency_key` in `attrs` to supply your own idempotency key.

# `delete_bucket`

```elixir
@spec delete_bucket(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Delete a bucket by ID.

# `delete_object`

```elixir
@spec delete_object(Miosa.Client.t(), String.t(), String.t()) ::
  Miosa.Client.result(map())
```

Delete an object from a bucket. The key is URL-encoded automatically.

# `get_bucket`

```elixir
@spec get_bucket(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Fetch a bucket by ID.

# `get_object`

```elixir
@spec get_object(Miosa.Client.t(), String.t(), String.t()) ::
  Miosa.Client.result(binary())
```

Download the raw bytes of an object.

The key is URL-encoded before being placed in the path.

# `list_buckets`

```elixir
@spec list_buckets(Miosa.Client.t()) :: Miosa.Client.result(map())
```

List all storage buckets for the authenticated tenant.

# `list_objects`

```elixir
@spec list_objects(Miosa.Client.t(), String.t(), keyword() | map()) ::
  Miosa.Client.result(map())
```

List objects in a bucket.

Options:
  * `:prefix` — Filter by key prefix.
  * `:limit` — Max objects to return.
  * `:cursor` — Pagination cursor.

# `presign`

```elixir
@spec presign(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Mint a presigned URL for direct browser upload or download.

Required `attrs`:
  * `:key` — Object key.

Optional `attrs`:
  * `:operation` — `"get"` (default) or `"put"`.
  * `:expires_in_sec` — Expiry in seconds. Defaults to `300`.
  * `:content_type` — Required for `"put"` uploads.

# `put_object`

```elixir
@spec put_object(Miosa.Client.t(), String.t(), String.t(), binary(), keyword()) ::
  Miosa.Client.result(map())
```

Upload bytes to an object key in a bucket.

`content_type` defaults to `"application/octet-stream"`.
The key is URL-encoded before being placed in the path.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
