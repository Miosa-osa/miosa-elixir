defmodule Miosa.Email do
  @moduledoc """
  Admin email surface with sub-modules for campaigns, templates, and inbox.

  Routes live under `/api/v1/admin/email-{campaigns,templates,inbox}/`
  and require an admin credential (`msk_a_*` / `msk_p_*` or admin JWT).

  ## Sub-modules

    * `Miosa.Email.Campaigns` — Bulk email send-out lifecycle
    * `Miosa.Email.Templates` — Reusable templates keyed by name
    * `Miosa.Email.Inbox` — Inbound and outbound direct messages
  """
end

defmodule Miosa.Email.Campaigns do
  @moduledoc """
  Admin email campaign lifecycle (GET/POST/etc. `/admin/email-campaigns`).
  """

  alias Miosa.Client

  @doc """
  List email campaigns (GET `/admin/email-campaigns`).
  """
  @spec list(Client.t(), map()) :: Client.result(list())
  def list(%Client{} = client, filters \\ %{}) do
    params = for {k, v} <- filters, v != nil, into: %{}, do: {k, v}
    opts = if map_size(params) > 0, do: [params: params], else: []

    case Client.get(client, "/admin/email-campaigns", opts) do
      {:ok, body} -> {:ok, unwrap_list(body)}
      err -> err
    end
  end

  @doc """
  Create an email campaign (POST `/admin/email-campaigns`).
  """
  @spec create(Client.t(), map()) :: Client.result(map())
  def create(%Client{} = client, attrs) when is_map(attrs) do
    body = for {k, v} <- attrs, v != nil, into: %{}, do: {to_string(k), v}

    client
    |> Client.post("/admin/email-campaigns", body)
    |> unwrap()
  end

  @doc """
  Get estimated recipient count (GET `/admin/email-campaigns/recipient-count`).
  """
  @spec recipient_count(Client.t(), map()) :: Client.result(map())
  def recipient_count(%Client{} = client, filters \\ %{}) do
    params = for {k, v} <- filters, v != nil, into: %{}, do: {k, v}
    opts = if map_size(params) > 0, do: [params: params], else: []

    client
    |> Client.get("/admin/email-campaigns/recipient-count", opts)
    |> unwrap()
  end

  @doc """
  Trigger send for a campaign (POST `/admin/email-campaigns/:campaign_id/send`).
  """
  @spec send(Client.t(), String.t(), map()) :: Client.result(map())
  def send(%Client{} = client, campaign_id, opts \\ %{}) when is_binary(campaign_id) do
    body = for {k, v} <- opts, v != nil, into: %{}, do: {to_string(k), v}

    client
    |> Client.post("/admin/email-campaigns/#{campaign_id}/send", body)
    |> unwrap()
  end

  @doc """
  Cancel a campaign (POST `/admin/email-campaigns/:campaign_id/cancel`).
  """
  @spec cancel(Client.t(), String.t()) :: Client.result(map())
  def cancel(%Client{} = client, campaign_id) when is_binary(campaign_id) do
    client
    |> Client.post("/admin/email-campaigns/#{campaign_id}/cancel")
    |> unwrap()
  end

  @doc """
  List per-recipient delivery records (GET `/admin/email-campaigns/:campaign_id/deliveries`).
  """
  @spec deliveries(Client.t(), String.t(), map()) :: Client.result(list())
  def deliveries(%Client{} = client, campaign_id, filters \\ %{}) when is_binary(campaign_id) do
    params = for {k, v} <- filters, v != nil, into: %{}, do: {k, v}
    opts = if map_size(params) > 0, do: [params: params], else: []

    case Client.get(client, "/admin/email-campaigns/#{campaign_id}/deliveries", opts) do
      {:ok, body} -> {:ok, unwrap_list(body)}
      err -> err
    end
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap_list(%{"data" => list}) when is_list(list), do: list
  defp unwrap_list(%{"campaigns" => list}) when is_list(list), do: list
  defp unwrap_list(%{"deliveries" => list}) when is_list(list), do: list
  defp unwrap_list(%{"items" => list}) when is_list(list), do: list
  defp unwrap_list(list) when is_list(list), do: list
  defp unwrap_list(_), do: []

  defp unwrap({:ok, %{"data" => data}}), do: {:ok, data}
  defp unwrap({:ok, body}), do: {:ok, body}
  defp unwrap(err), do: err
end

defmodule Miosa.Email.Templates do
  @moduledoc """
  Reusable email templates keyed by name (`/admin/email-templates`).
  """

  alias Miosa.Client

  @doc """
  List email templates (GET `/admin/email-templates`).
  """
  @spec list(Client.t(), map()) :: Client.result(list())
  def list(%Client{} = client, filters \\ %{}) do
    params = for {k, v} <- filters, v != nil, into: %{}, do: {k, v}
    opts = if map_size(params) > 0, do: [params: params], else: []

    case Client.get(client, "/admin/email-templates", opts) do
      {:ok, body} -> {:ok, unwrap_list(body)}
      err -> err
    end
  end

  @doc """
  Create an email template (POST `/admin/email-templates`).

  `key` is required — it uniquely identifies the template.
  """
  @spec create(Client.t(), String.t(), map()) :: Client.result(map())
  def create(%Client{} = client, key, attrs \\ %{}) when is_binary(key) do
    body =
      attrs
      |> Enum.reduce(%{"key" => key}, fn {k, v}, acc ->
        if v != nil, do: Map.put(acc, to_string(k), v), else: acc
      end)

    client
    |> Client.post("/admin/email-templates", body)
    |> unwrap()
  end

  @doc """
  Update an email template (PUT `/admin/email-templates/:key`).
  """
  @spec update(Client.t(), String.t(), map()) :: Client.result(map())
  def update(%Client{} = client, key, attrs) when is_binary(key) and is_map(attrs) do
    body = for {k, v} <- attrs, v != nil, into: %{}, do: {to_string(k), v}

    client
    |> Client.put("/admin/email-templates/#{key}", body)
    |> unwrap()
  end

  @doc """
  Reset an email template to platform default (POST `/admin/email-templates/:key/reset`).
  """
  @spec reset(Client.t(), String.t()) :: Client.result(map())
  def reset(%Client{} = client, key) when is_binary(key) do
    client
    |> Client.post("/admin/email-templates/#{key}/reset")
    |> unwrap()
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap_list(%{"data" => list}) when is_list(list), do: list
  defp unwrap_list(%{"templates" => list}) when is_list(list), do: list
  defp unwrap_list(%{"items" => list}) when is_list(list), do: list
  defp unwrap_list(list) when is_list(list), do: list
  defp unwrap_list(_), do: []

  defp unwrap({:ok, %{"data" => data}}), do: {:ok, data}
  defp unwrap({:ok, body}), do: {:ok, body}
  defp unwrap(err), do: err
end

defmodule Miosa.Email.Inbox do
  @moduledoc """
  Inbound and outbound direct messages (`/admin/email-inbox`).
  """

  alias Miosa.Client

  @doc """
  List inbox messages (GET `/admin/email-inbox`).
  """
  @spec list(Client.t(), map()) :: Client.result(list())
  def list(%Client{} = client, filters \\ %{}) do
    params = for {k, v} <- filters, v != nil, into: %{}, do: {k, v}
    opts = if map_size(params) > 0, do: [params: params], else: []

    case Client.get(client, "/admin/email-inbox", opts) do
      {:ok, body} -> {:ok, unwrap_list(body)}
      err -> err
    end
  end

  @doc """
  Send a direct message (POST `/admin/email-inbox/send`).
  """
  @spec send(Client.t(), map()) :: Client.result(map())
  def send(%Client{} = client, attrs) when is_map(attrs) do
    body = for {k, v} <- attrs, v != nil, into: %{}, do: {to_string(k), v}

    client
    |> Client.post("/admin/email-inbox/send", body)
    |> unwrap()
  end

  @doc """
  Mark a message as read (POST `/admin/email-inbox/:message_id/read`).
  """
  @spec mark_read(Client.t(), String.t()) :: Client.result(map())
  def mark_read(%Client{} = client, message_id) when is_binary(message_id) do
    client
    |> Client.post("/admin/email-inbox/#{message_id}/read")
    |> unwrap()
  end

  @doc """
  Archive a message (POST `/admin/email-inbox/:message_id/archive`).
  """
  @spec archive(Client.t(), String.t()) :: Client.result(map())
  def archive(%Client{} = client, message_id) when is_binary(message_id) do
    client
    |> Client.post("/admin/email-inbox/#{message_id}/archive")
    |> unwrap()
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap_list(%{"data" => list}) when is_list(list), do: list
  defp unwrap_list(%{"inbox" => list}) when is_list(list), do: list
  defp unwrap_list(%{"items" => list}) when is_list(list), do: list
  defp unwrap_list(list) when is_list(list), do: list
  defp unwrap_list(_), do: []

  defp unwrap({:ok, %{"data" => data}}), do: {:ok, data}
  defp unwrap({:ok, body}), do: {:ok, body}
  defp unwrap(err), do: err
end
