defmodule Miosa.Quotas do
  @moduledoc """
  Per-`external_user_id` quota management — override the tenant defaults for
  individual end-users of your platform.

  Wraps:
    * `GET    /api/v1/quotas/external/:external_user_id` — get/2
    * `PUT    /api/v1/quotas/external/:external_user_id` — set/3
    * `DELETE /api/v1/quotas/external/:external_user_id` — delete/2

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

      {:ok, _} = Miosa.Quotas.set(client, "user-123", %{
        max_sandboxes: 5,
        max_concurrent: 2,
        max_storage_gb: 20,
        max_credit_cents: 5000
      })

      {:ok, quota} = Miosa.Quotas.get(client, "user-123")
      IO.inspect(quota)

      :ok = Miosa.Quotas.delete(client, "user-123")
  """

  alias Miosa.Client

  @doc """
  Get current quota limits + usage for an external user.
  """
  @spec get(Client.t(), String.t()) :: Client.result(map())
  def get(%Client{} = client, external_user_id) when is_binary(external_user_id) do
    case Client.get(client, "/quotas/external/#{external_user_id}") do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, body} -> {:ok, body}
      err -> err
    end
  end

  @doc """
  Set quota overrides for an external user.

  Accepted keys (atom or string): `:max_sandboxes`, `:max_concurrent`,
  `:max_storage_gb`, `:max_credit_cents`.
  """
  @spec set(Client.t(), String.t(), map()) :: Client.result(map())
  def set(%Client{} = client, external_user_id, limits)
      when is_binary(external_user_id) and is_map(limits) do
    body = stringify_keys(limits)

    case Client.put(client, "/quotas/external/#{external_user_id}", body) do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, body} -> {:ok, body}
      err -> err
    end
  end

  @doc """
  Revert an external user's quota to the tenant default.
  """
  @spec delete(Client.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def delete(%Client{} = client, external_user_id) when is_binary(external_user_id) do
    case Client.delete(client, "/quotas/external/#{external_user_id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ---------------------------------------------------------------------------

  defp stringify_keys(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), v}
      {k, v} -> {k, v}
    end)
  end
end
