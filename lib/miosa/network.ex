defmodule Miosa.Network do
  @moduledoc """
  Tenant-wide egress network policy and allowlist management.

  Backed by `/api/v1/egress/policies`, `/api/v1/egress/allowlist`, and
  `/api/v1/egress/audit/suggestions`.

  The egress firewall operates in two modes:

    * **`enforce`** — denied requests are actively blocked.
    * **`audit_only`** — requests are logged but never blocked (observe mode).

  Use `observe/2` to run in shadow mode during rollout, then `lockdown/2`
  when you are ready to enforce.

  ## Client-level usage

      client = Miosa.client("msk_u_...")

      {:ok, rule}    = Miosa.Network.allow(client, "api.github.com")
      {:ok, rule}    = Miosa.Network.deny(client, "suspicious.host.io")
      {:ok, policy}  = Miosa.Network.lockdown(client)
      {:ok, policy}  = Miosa.Network.observe(client)
      {:ok, items}   = Miosa.Network.suggestions(client)
      {:ok, policies}= Miosa.Network.policies(client)
      {:ok, rules}   = Miosa.Network.rules(client, policy_id)

  ## Sandbox-bound usage

  See `Miosa.Sandboxes.Network` for the resource-scoped variant.
  """

  alias Miosa.Client

  @policy_path "/egress/policies"
  @allowlist_path "/egress/allowlist"
  @suggestions_path "/egress/audit/suggestions"

  # ---------------------------------------------------------------------------
  # Allowlist rules
  # ---------------------------------------------------------------------------

  @doc """
  Add an `allow` rule for `host` to the tenant egress allowlist.

  ## Options (as keyword list)

    * `:methods` — list of HTTP methods to allow. `nil` = all.
    * `:path_glob` — glob pattern to restrict path scope.
    * `:policy_id` — attach to a named policy.
    * `:resource_id`, `:resource_type` — scope to a specific resource.
    * `:note` — human-readable description.
  """
  @spec allow(Client.t(), String.t(), keyword()) :: Client.result(map())
  def allow(%Client{} = client, host, opts \\ []) when is_binary(host) do
    post_allowlist_rule(client, host, "allow", opts)
  end

  @doc """
  Add a `deny` rule for `host` to the tenant egress allowlist.

  Accepts the same options as `allow/3`.
  """
  @spec deny(Client.t(), String.t(), keyword()) :: Client.result(map())
  def deny(%Client{} = client, host, opts \\ []) when is_binary(host) do
    post_allowlist_rule(client, host, "deny", opts)
  end

  @doc """
  List allowlist rules.

  Accepts optional filters as a keyword list: `policy_id`, `resource_id`,
  `resource_type`.
  """
  @spec rules(Client.t(), String.t() | nil, keyword()) :: Client.result([map()])
  def rules(%Client{} = client, policy_id \\ nil, filters \\ []) do
    params =
      filters
      |> Keyword.put_new_lazy(:policy_id, fn -> policy_id end)
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)

    case Client.get(client, @allowlist_path, params: params) do
      {:ok, data} -> {:ok, unwrap_list(data)}
      err -> err
    end
  end

  @doc """
  Delete an allowlist rule by ID.
  """
  @spec remove_rule(Client.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def remove_rule(%Client{} = client, rule_id) when is_binary(rule_id) do
    case Client.delete(client, "#{@allowlist_path}/#{rule_id}") do
      {:ok, _} -> :ok
      {:error, _} = err -> err
    end
  end

  # ---------------------------------------------------------------------------
  # Policies
  # ---------------------------------------------------------------------------

  @doc """
  List egress policies.

  Accepts optional filters as a keyword list.
  """
  @spec policies(Client.t(), keyword()) :: Client.result([map()])
  def policies(%Client{} = client, filters \\ []) do
    params = Enum.reject(filters, fn {_k, v} -> is_nil(v) end)

    case Client.get(client, @policy_path, params: params) do
      {:ok, data} -> {:ok, unwrap_list(data)}
      err -> err
    end
  end

  @doc """
  Create a new egress policy.

  ## Required attrs

    * `:name`

  ## Optional attrs

    * `:mode` — `"enforce"` (default) or `"audit_only"`.
    * `:default_effect` — `"deny"` (default) or `"allow"`.
    * `:resource_id`, `:resource_type` — scope to a specific resource.
    * `:description`
  """
  @spec create_policy(Client.t(), map()) :: Client.result(map())
  def create_policy(%Client{} = client, attrs) when is_map(attrs) do
    body = strip_nil(attrs)

    case Client.post(client, @policy_path, body) do
      {:ok, data} -> {:ok, unwrap(data)}
      err -> err
    end
  end

  @doc """
  Update an existing egress policy.

  `attrs` may include `:mode`, `:default_effect`, `:name`, `:description`.
  """
  @spec update_policy(Client.t(), String.t(), map()) :: Client.result(map())
  def update_policy(%Client{} = client, policy_id, attrs)
      when is_binary(policy_id) and is_map(attrs) do
    body = strip_nil(attrs)

    case Client.patch(client, "#{@policy_path}/#{policy_id}", body) do
      {:ok, data} -> {:ok, unwrap(data)}
      err -> err
    end
  end

  # ---------------------------------------------------------------------------
  # Mode helpers
  # ---------------------------------------------------------------------------

  @doc """
  Set the policy to `mode=enforce` — denied requests are blocked.

  ## Options (keyword)

    * `:policy_id` — target a specific policy. When absent, the tenant
      default policy is patched.
    * `:resource_id`, `:resource_type` — resource-scoped patch.
  """
  @spec lockdown(Client.t(), keyword()) :: Client.result(map())
  def lockdown(%Client{} = client, opts \\ []) do
    set_mode(client, "enforce", opts)
  end

  @doc """
  Set the policy to `mode=audit_only` — requests are logged but not blocked.

  Accepts the same options as `lockdown/2`.
  """
  @spec observe(Client.t(), keyword()) :: Client.result(map())
  def observe(%Client{} = client, opts \\ []) do
    set_mode(client, "audit_only", opts)
  end

  # ---------------------------------------------------------------------------
  # Suggestions
  # ---------------------------------------------------------------------------

  @doc """
  Return AI-generated allowlist suggestions based on recent denied egress traffic.

  ## Options (keyword)

    * `:resource_id`, `:resource_type` — scope to a specific resource.
    * `:since` — lookback window, e.g. `"7d"` (default), `"24h"`.
  """
  @spec suggestions(Client.t(), keyword()) :: Client.result([map()])
  def suggestions(%Client{} = client, opts \\ []) do
    params =
      opts
      |> Keyword.put_new(:since, "7d")
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)

    case Client.get(client, @suggestions_path, params: params) do
      {:ok, data} -> {:ok, unwrap_list(data)}
      err -> err
    end
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp post_allowlist_rule(client, host, effect, opts) do
    body =
      opts
      |> Enum.into(%{})
      |> Map.put(:host, host)
      |> Map.put(:effect, effect)
      |> strip_nil()

    case Client.post(client, @allowlist_path, body) do
      {:ok, data} -> {:ok, unwrap(data)}
      err -> err
    end
  end

  defp set_mode(client, mode, opts) do
    policy_id = Keyword.get(opts, :policy_id)
    resource_id = Keyword.get(opts, :resource_id)
    resource_type = Keyword.get(opts, :resource_type)

    cond do
      policy_id != nil ->
        update_policy(client, policy_id, %{mode: mode})

      resource_id != nil and resource_type != nil ->
        body = strip_nil(%{mode: mode, resource_id: resource_id, resource_type: resource_type})

        case Client.patch(client, @policy_path, body) do
          {:ok, data} -> {:ok, unwrap(data)}
          err -> err
        end

      true ->
        case Client.patch(client, @policy_path, %{mode: mode}) do
          {:ok, data} -> {:ok, unwrap(data)}
          err -> err
        end
    end
  end

  @spec strip_nil(map()) :: map()
  defp strip_nil(map) when is_map(map) do
    Map.reject(map, fn {_k, v} -> is_nil(v) end)
  end

  @spec unwrap(any()) :: any()
  defp unwrap(%{"data" => inner} = map) when map_size(map) <= 2, do: inner
  defp unwrap(%{"policy" => inner} = map) when map_size(map) <= 2, do: inner
  defp unwrap(%{"rule" => inner} = map) when map_size(map) <= 2, do: inner
  defp unwrap(other), do: other

  @spec unwrap_list(any()) :: [map()]
  defp unwrap_list(list) when is_list(list), do: list

  defp unwrap_list(map) when is_map(map) do
    keys = ["data", "policies", "rules", "allowlist", "suggestions", "items"]

    Enum.find_value(keys, [], fn key ->
      case Map.get(map, key) do
        list when is_list(list) -> list
        _ -> nil
      end
    end)
  end

  defp unwrap_list(_), do: []
end
