defmodule Miosa.Dashboard do
  @moduledoc """
  Dashboard — aggregated platform overview, polled on login.

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

      {:ok, summary} = Miosa.Dashboard.summary(client)
  """

  alias Miosa.Client

  @doc "Get the aggregated user dashboard payload."
  @spec summary(Client.t()) :: Client.result(map())
  def summary(client) do
    Client.get(client, "/dashboard")
  end

  @doc "Get the platform status and health overview (public endpoint)."
  @spec overview(Client.t()) :: Client.result(map())
  def overview(client) do
    Client.get(client, "/overview")
  end
end
