defmodule Miosa.Webhooks do
  @moduledoc """
  Tenant-level outgoing webhooks — CRUD, test delivery, and delivery history.

  Mutating calls (create, update, test) send an `Idempotency-Key` header
  automatically.

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

      {:ok, wh} = Miosa.Webhooks.create(client, %{
        url: "https://api.example.com/hooks/miosa",
        events: ["computer.started", "computer.stopped"],
        secret: "whsec_..."
      })

      {:ok, _} = Miosa.Webhooks.test(client, wh["id"])
      {:ok, deliveries} = Miosa.Webhooks.deliveries(client, wh["id"])
  """

  alias Miosa.Client

  # ── CRUD ─────────────────────────────────────────────────────────────────────

  @doc """
  List webhooks for the authenticated tenant.

  Accepts optional filters as a keyword list or map (e.g. `:limit`, `:cursor`).
  """
  @spec list(Client.t(), keyword() | map()) :: Client.result(map())
  def list(client, filters \\ []) do
    query = filters |> normalize() |> build_query()
    Client.get(client, "/webhooks" <> query)
  end

  @doc "Fetch a webhook by ID."
  @spec get(Client.t(), String.t()) :: Client.result(map())
  def get(client, webhook_id) when is_binary(webhook_id) do
    Client.get(client, "/webhooks/" <> webhook_id)
  end

  @doc """
  Create a webhook.

  Required: `:url`, `:events` (list of event type strings).
  Optional: `:secret`, `:enabled`, `:metadata`, `:idempotency_key`.
  """
  @spec create(Client.t(), map()) :: Client.result(map())
  def create(client, attrs) when is_map(attrs) do
    idem = pop_idempotency(attrs)
    Client.post(client, "/webhooks", strip_nil(attrs), headers: [{"idempotency-key", idem}])
  end

  @doc """
  Update a webhook.

  Pass any fields to update; nil values are dropped.
  """
  @spec update(Client.t(), String.t(), map()) :: Client.result(map())
  def update(client, webhook_id, attrs) when is_binary(webhook_id) and is_map(attrs) do
    Client.patch(client, "/webhooks/" <> webhook_id, strip_nil(attrs))
  end

  @doc "Delete a webhook by ID."
  @spec delete(Client.t(), String.t()) :: Client.result(map())
  def delete(client, webhook_id) when is_binary(webhook_id) do
    Client.delete(client, "/webhooks/" <> webhook_id)
  end

  # ── Test + deliveries ────────────────────────────────────────────────────────

  @doc "Send a test event to verify the webhook endpoint is reachable."
  @spec test(Client.t(), String.t()) :: Client.result(map())
  def test(client, webhook_id) when is_binary(webhook_id) do
    idem = generate_idempotency_key()
    Client.post(client, "/webhooks/#{webhook_id}/test", nil, headers: [{"idempotency-key", idem}])
  end

  @doc """
  List recent delivery attempts for a webhook.

  Accepts optional filters as a keyword list or map (e.g. `:limit`, `:cursor`).
  """
  @spec deliveries(Client.t(), String.t(), keyword() | map()) :: Client.result(map())
  def deliveries(client, webhook_id, filters \\ []) when is_binary(webhook_id) do
    query = filters |> normalize() |> build_query()
    Client.get(client, "/webhooks/#{webhook_id}/deliveries" <> query)
  end

  @doc """
  Verify a MIOSA webhook signature header.

  The expected header format is `t=<unix_seconds>,v1=<hex_hmac>`.
  """
  @spec verify_signature(binary(), binary(), binary(), non_neg_integer()) ::
          {:ok, true}
          | {:error, :malformed_header | :timestamp_too_old | :invalid_signature}
  def verify_signature(payload, header, secret, tolerance_seconds \\ 300)
      when is_binary(payload) and is_binary(header) and is_binary(secret) do
    with {:ok, timestamp, signature} <- parse_signature_header(header),
         :ok <- check_timestamp(timestamp, tolerance_seconds),
         true <- valid_signature?(payload, timestamp, secret, signature) do
      {:ok, true}
    else
      {:error, reason} -> {:error, reason}
      false -> {:error, :invalid_signature}
    end
  end

  # ── Helpers ──────────────────────────────────────────────────────────────────

  defp parse_signature_header(header) do
    parts =
      header
      |> String.split(",", trim: true)
      |> Enum.map(fn part ->
        case String.split(part, "=", parts: 2) do
          [key, value] -> {key, value}
          _ -> nil
        end
      end)

    with {_, timestamp_raw} <- Enum.find(parts, fn part -> match?({"t", _}, part) end),
         {_, signature} <- Enum.find(parts, fn part -> match?({"v1", _}, part) end),
         {timestamp, ""} <- Integer.parse(timestamp_raw) do
      {:ok, timestamp, signature}
    else
      _ -> {:error, :malformed_header}
    end
  end

  defp check_timestamp(timestamp, tolerance_seconds) do
    now = System.os_time(:second)

    if abs(now - timestamp) <= tolerance_seconds do
      :ok
    else
      {:error, :timestamp_too_old}
    end
  end

  defp valid_signature?(payload, timestamp, secret, signature) do
    expected =
      :crypto.mac(:hmac, :sha256, secret, "#{timestamp}.#{payload}")
      |> Base.encode16(case: :lower)

    secure_compare(expected, signature)
  end

  defp secure_compare(left, right) when byte_size(left) == byte_size(right) do
    secure_compare(left, right, 0) == 0
  end

  defp secure_compare(_left, _right), do: false

  defp secure_compare(<<left, left_rest::binary>>, <<right, right_rest::binary>>, acc) do
    secure_compare(left_rest, right_rest, :erlang.bor(acc, :erlang.bxor(left, right)))
  end

  defp secure_compare(<<>>, <<>>, acc), do: acc

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
