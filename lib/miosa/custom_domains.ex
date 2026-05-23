defmodule Miosa.CustomDomains do
  @moduledoc """
  Register and verify custom domains for MIOSA computers.

  Custom domains allow you to expose a service running inside a computer at
  a user-friendly hostname (e.g. `app.example.com`) instead of the default
  generated URL.

  ## Workflow

  1. `register/3` — claim the domain against a computer + port.
  2. Follow the DNS instructions returned in the `CustomDomain` struct.
  3. `verify/3` — trigger domain verification; status transitions to `:active`.
  4. `delete/3` — remove the domain when no longer needed.

  ## Example

      {:ok, domain} = Miosa.CustomDomains.register(client, computer_id, %{
        domain: "app.example.com",
        port: 3000
      })

      {:ok, domains} = Miosa.CustomDomains.list(client, computer_id)
      {:ok, domain} = Miosa.CustomDomains.verify(client, computer_id, domain.id)
      :ok = Miosa.CustomDomains.delete(client, computer_id, domain.id)

  """

  alias Miosa.{Client, Types}

  @type register_params :: %{
          required(:domain) => String.t(),
          optional(:port) => pos_integer(),
          optional(:tls) => boolean()
        }

  @doc """
  Registers a custom domain for a computer.

  ## Params

    * `:domain` — Required. The fully-qualified domain name.
    * `:port` — Port inside the computer to route traffic to. Defaults to `80`.
    * `:tls` — Whether to provision TLS. Defaults to `true`.

  Returns a `CustomDomain` struct whose `:dns_instructions` field contains
  the CNAME or A-record value to configure with your DNS provider.
  """
  @spec register(Client.t(), String.t(), register_params()) ::
          Client.result(Types.CustomDomain.t())
  def register(%Client{} = client, computer_id, params)
      when is_binary(computer_id) and is_map(params) do
    client
    |> Client.post("/computers/#{computer_id}/domains", stringify_keys(params))
    |> unwrap_domain()
  end

  @doc """
  Lists all custom domains registered for a computer.
  """
  @spec list(Client.t(), String.t()) :: Client.result([Types.CustomDomain.t()])
  def list(%Client{} = client, computer_id) when is_binary(computer_id) do
    case Client.get(client, "/computers/#{computer_id}/domains") do
      {:ok, body} ->
        domains =
          body
          |> get_list()
          |> Enum.map(&Types.CustomDomain.from_map/1)

        {:ok, domains}

      {:error, _} = err ->
        err
    end
  end

  @doc """
  Triggers domain ownership verification.

  The API checks that the required DNS record is in place. On success the
  domain transitions to `:active` status.

  Returns the updated `CustomDomain` struct.
  """
  @spec verify(Client.t(), String.t(), String.t()) :: Client.result(Types.CustomDomain.t())
  def verify(%Client{} = client, computer_id, domain_id)
      when is_binary(computer_id) and is_binary(domain_id) do
    client
    |> Client.post("/computers/#{computer_id}/domains/#{domain_id}/verify")
    |> unwrap_domain()
  end

  @doc """
  Removes a custom domain registration.

  In-flight requests to the domain will immediately return 404 after deletion.
  """
  @spec delete(Client.t(), String.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def delete(%Client{} = client, computer_id, domain_id)
      when is_binary(computer_id) and is_binary(domain_id) do
    client
    |> Client.delete("/computers/#{computer_id}/domains/#{domain_id}")
    |> to_ok()
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap_domain({:ok, body}) do
    domain = body |> get_resource() |> Types.CustomDomain.from_map()
    {:ok, domain}
  end

  defp unwrap_domain({:error, _} = err), do: err

  defp to_ok({:ok, _}), do: :ok
  defp to_ok({:error, _} = err), do: err

  defp get_resource(%{"data" => data}) when is_map(data), do: data
  defp get_resource(%{"domain" => data}) when is_map(data), do: data
  defp get_resource(map) when is_map(map), do: map

  defp get_list(%{"data" => list}) when is_list(list), do: list
  defp get_list(%{"domains" => list}) when is_list(list), do: list
  defp get_list(list) when is_list(list), do: list
  defp get_list(_), do: []

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end
end
