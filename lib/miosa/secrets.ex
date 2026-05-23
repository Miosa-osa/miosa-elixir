defmodule Miosa.Secrets do
  @moduledoc """
  Tenant-wide egress secret and OAuth credential vault.

  Backed by `/api/v1/egress/secrets`, `/api/v1/egress/bindings`, and
  `/api/v1/egress/oauth/*`.

  Secrets are encrypted at rest and can be injected into sandboxes or
  computers as environment variables via **bindings**. The OAuth connect
  flow creates secrets automatically once the user completes the grant.

  ## Client-level usage

      client = Miosa.client("msk_u_...")

      {:ok, secret}  = Miosa.Secrets.set(client, %{name: "gh_token", value: "ghp_..."})
      {:ok, secrets} = Miosa.Secrets.list(client)
      {:ok, secret}  = Miosa.Secrets.get(client, secret_id)
      {:ok, secret}  = Miosa.Secrets.rotate(client, secret_id, %{value: "new_val"})
      :ok            = Miosa.Secrets.delete(client, secret_id)

      {:ok, flow} = Miosa.Secrets.connect(client, "github")
      IO.puts("Authorize at: " <> flow.authorize_url)
      {:ok, result} = Miosa.OauthFlow.wait_for_completion(flow)

  ## Sandbox-bound usage

  See `Miosa.Sandboxes.Secrets` for the resource-scoped variant that
  pre-populates `resource_id` and `resource_type="sandbox"`.
  """

  alias Miosa.{Client, OauthFlow}

  @secret_path "/egress/secrets"
  @binding_path "/egress/bindings"
  @oauth_providers_path "/egress/oauth/providers"
  @oauth_start_path "/egress/oauth/start"

  # ---------------------------------------------------------------------------
  # Secrets CRUD
  # ---------------------------------------------------------------------------

  @doc """
  Create or upsert a secret.

  ## Required attrs

    * `:name` — identifier for the secret.
    * `:value` — plaintext value to encrypt.

  ## Optional attrs

    * `:type` — `"api_key"` (default), `"oauth_token"`, `"env_var"`, etc.
    * `:scope` — `"user"` (default) or `"workspace"`.
    * `:expose_as_env` — when provided alongside `:resource_id`, the backend
      also creates a binding so the value is injected as this env-var name.
    * `:workspace_id`, `:owner_user_id`, `:external_user_id`,
      `:external_workspace_id` — attribution fields.
    * `:resource_id`, `:resource_type` — scope to a specific resource.
    * `:refresh_token`, `:expires_at` — OAuth token fields.
    * `:metadata` — arbitrary map stored alongside the secret.
  """
  @spec set(Client.t(), map()) :: Client.result(map())
  def set(%Client{} = client, attrs) when is_map(attrs) do
    body = strip_nil(attrs)

    case Client.post(client, @secret_path, body) do
      {:ok, data} -> {:ok, unwrap(data)}
      err -> err
    end
  end

  @doc """
  List secrets for the current tenant.

  Accepts optional filter keys as a map: `resource_id`, `resource_type`,
  `scope`, `type`, `workspace_id`, `owner_user_id`, `external_user_id`,
  `external_workspace_id`.
  """
  @spec list(Client.t(), map()) :: Client.result([map()])
  def list(%Client{} = client, filters \\ %{}) do
    params = filters |> strip_nil() |> map_to_keyword()

    case Client.get(client, @secret_path, params: params) do
      {:ok, data} -> {:ok, unwrap_list(data)}
      err -> err
    end
  end

  @doc """
  Fetch a single secret by ID.
  """
  @spec get(Client.t(), String.t()) :: Client.result(map())
  def get(%Client{} = client, secret_id) when is_binary(secret_id) do
    case Client.get(client, "#{@secret_path}/#{secret_id}") do
      {:ok, data} -> {:ok, unwrap(data)}
      err -> err
    end
  end

  @doc """
  Rotate a secret's value.

  `attrs` should contain at minimum `:value`. Optional: `:refresh_token`,
  `:expires_at`.
  """
  @spec rotate(Client.t(), String.t(), map()) :: Client.result(map())
  def rotate(%Client{} = client, secret_id, attrs) when is_binary(secret_id) and is_map(attrs) do
    body = strip_nil(attrs)

    case Client.patch(client, "#{@secret_path}/#{secret_id}", body) do
      {:ok, data} -> {:ok, unwrap(data)}
      err -> err
    end
  end

  @doc """
  Delete a secret by ID.

  Returns `:ok` on success.
  """
  @spec delete(Client.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def delete(%Client{} = client, secret_id) when is_binary(secret_id) do
    case Client.delete(client, "#{@secret_path}/#{secret_id}") do
      {:ok, _} -> :ok
      {:error, _} = err -> err
    end
  end

  # ---------------------------------------------------------------------------
  # Bindings
  # ---------------------------------------------------------------------------

  @doc """
  Explicitly bind an existing secret to a resource.

  ## Required attrs

    * `:secret_id`
    * `:resource_id`
    * `:resource_type` — `"sandbox"` or `"computer"`
    * `:expose_as_env` — the environment variable name to inject
  """
  @spec create_binding(Client.t(), map()) :: Client.result(map())
  def create_binding(%Client{} = client, attrs) when is_map(attrs) do
    body = strip_nil(attrs)

    case Client.post(client, @binding_path, body) do
      {:ok, data} -> {:ok, unwrap(data)}
      err -> err
    end
  end

  @doc """
  List bindings. Accepts optional filters: `resource_id`, `resource_type`,
  `secret_id`.
  """
  @spec list_bindings(Client.t(), map()) :: Client.result([map()])
  def list_bindings(%Client{} = client, filters \\ %{}) do
    params = filters |> strip_nil() |> map_to_keyword()

    case Client.get(client, @binding_path, params: params) do
      {:ok, data} -> {:ok, unwrap_list(data)}
      err -> err
    end
  end

  @doc """
  Delete a binding by ID.
  """
  @spec delete_binding(Client.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def delete_binding(%Client{} = client, binding_id) when is_binary(binding_id) do
    case Client.delete(client, "#{@binding_path}/#{binding_id}") do
      {:ok, _} -> :ok
      {:error, _} = err -> err
    end
  end

  # ---------------------------------------------------------------------------
  # OAuth
  # ---------------------------------------------------------------------------

  @doc """
  List OAuth providers available to the current tenant.
  """
  @spec providers(Client.t()) :: Client.result([map()])
  def providers(%Client{} = client) do
    case Client.get(client, @oauth_providers_path) do
      {:ok, data} -> {:ok, unwrap_list(data, ["data", "providers", "items"])}
      err -> err
    end
  end

  @doc """
  Start an OAuth Connect flow for `provider` (e.g. `"github"`, `"slack"`).

  Returns `{:ok, %Miosa.OauthFlow{}}`. The caller must open
  `flow.authorize_url` in the end user's browser and then call
  `Miosa.OauthFlow.wait_for_completion/2`.

  ## Options (as map attrs)

    * `:expose_as_env`, `:scope`, `:owner_user_id`, `:external_user_id`,
      `:external_workspace_id`, `:resource_id`, `:resource_type`,
      `:redirect_uri` — all optional.
  """
  @spec connect(Client.t(), String.t(), map()) :: Client.result(OauthFlow.t())
  def connect(%Client{} = client, provider, opts \\ %{})
      when is_binary(provider) do
    body =
      opts
      |> Map.put(:provider, provider)
      |> strip_nil()

    case Client.post(client, @oauth_start_path, body) do
      {:ok, data} ->
        payload = unwrap(data)

        flow = %OauthFlow{
          authorize_url:
            to_string(Map.get(payload, "authorize_url") || Map.get(payload, "authorizeUrl") || ""),
          state: to_string(Map.get(payload, "state") || ""),
          provider: provider,
          client: client,
          data: payload
        }

        {:ok, flow}

      err ->
        err
    end
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  @spec strip_nil(map()) :: map()
  defp strip_nil(map) when is_map(map) do
    Map.reject(map, fn {_k, v} -> is_nil(v) end)
  end

  @spec map_to_keyword(map()) :: keyword()
  defp map_to_keyword(map) when is_map(map) do
    Enum.map(map, fn {k, v} -> {to_key(k), v} end)
  end

  defp to_key(k) when is_atom(k), do: k
  defp to_key(k) when is_binary(k), do: String.to_existing_atom(k)

  @spec unwrap(any()) :: any()
  defp unwrap(%{"data" => inner} = map) when map_size(map) <= 2, do: inner
  defp unwrap(%{"secret" => inner} = map) when map_size(map) <= 2, do: inner
  defp unwrap(%{"binding" => inner} = map) when map_size(map) <= 2, do: inner
  defp unwrap(other), do: other

  @spec unwrap_list(any(), [String.t()]) :: [map()]
  defp unwrap_list(data, keys \\ ["data", "secrets", "bindings", "items"])

  defp unwrap_list(list, _keys) when is_list(list), do: list

  defp unwrap_list(map, keys) when is_map(map) do
    Enum.find_value(keys, [], fn key ->
      case Map.get(map, key) do
        list when is_list(list) -> list
        _ -> nil
      end
    end)
  end

  defp unwrap_list(_, _), do: []
end
