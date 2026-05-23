defmodule Miosa.NetworkPolicy do
  @moduledoc """
  Read and write the network egress/ingress policy for a MIOSA computer.

  A network policy controls which hosts and ports a computer can reach on the
  public internet. The default policy allows all outbound traffic.

  ## Example

      {:ok, policy} = Miosa.NetworkPolicy.get(client, computer_id)

      {:ok, policy} = Miosa.NetworkPolicy.set(client, computer_id, %{
        rules: [
          %{direction: "egress", action: "allow", host: "api.example.com", port: 443},
          %{direction: "egress", action: "deny",  host: "*", port: "*"}
        ]
      })

      :ok = Miosa.NetworkPolicy.reset(client, computer_id)

  """

  alias Miosa.{Client, Types}

  @type policy_params :: %{
          required(:rules) => [rule_params()]
        }

  @type rule_params :: %{
          required(:direction) => String.t(),
          required(:action) => String.t(),
          optional(:host) => String.t(),
          optional(:port) => String.t() | pos_integer()
        }

  @doc """
  Returns the current network policy for a computer.
  """
  @spec get(Client.t(), String.t()) :: Client.result(Types.NetworkPolicy.t())
  def get(%Client{} = client, computer_id) when is_binary(computer_id) do
    case Client.get(client, "/computers/#{computer_id}/network-policy") do
      {:ok, body} ->
        policy = body |> get_resource() |> Types.NetworkPolicy.from_map()
        {:ok, policy}

      {:error, _} = err ->
        err
    end
  end

  @doc """
  Replaces the network policy for a computer.

  The supplied rules fully replace the existing policy.

  ## Params

    * `:rules` — Required. List of rule maps with `:direction`, `:action`,
      and optionally `:host` and `:port`.

  """
  @spec set(Client.t(), String.t(), policy_params()) :: Client.result(Types.NetworkPolicy.t())
  def set(%Client{} = client, computer_id, params)
      when is_binary(computer_id) and is_map(params) do
    case Client.put(client, "/computers/#{computer_id}/network-policy", stringify_keys(params)) do
      {:ok, body} ->
        policy = body |> get_resource() |> Types.NetworkPolicy.from_map()
        {:ok, policy}

      {:error, _} = err ->
        err
    end
  end

  @doc """
  Resets the network policy to the default (allow all outbound) for a computer.
  """
  @spec reset(Client.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def reset(%Client{} = client, computer_id) when is_binary(computer_id) do
    client
    |> Client.delete("/computers/#{computer_id}/network-policy")
    |> to_ok()
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp to_ok({:ok, _}), do: :ok
  defp to_ok({:error, _} = err), do: err

  defp get_resource(%{"data" => data}) when is_map(data), do: data
  defp get_resource(%{"policy" => data}) when is_map(data), do: data
  defp get_resource(map) when is_map(map), do: map

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} ->
      v = if is_map(v), do: stringify_keys(v), else: v
      {to_string(k), v}
    end)
  end
end
