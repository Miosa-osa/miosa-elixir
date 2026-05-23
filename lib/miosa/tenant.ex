defmodule Miosa.Tenant do
  @moduledoc """
  Current tenant info — plan limits and live usage counters.

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

      {:ok, plan} = Miosa.Tenant.current(client)
      IO.inspect(plan["plan"])
  """

  alias Miosa.Client

  @doc """
  Get the current tenant's plan, limits, and live usage counters.
  """
  @spec current(Client.t()) :: Client.result(map())
  def current(client) do
    Client.get(client, "/tenant/plan")
  end
end
