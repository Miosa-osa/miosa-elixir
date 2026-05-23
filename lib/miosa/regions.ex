defmodule Miosa.Regions do
  @moduledoc """
  Datacenter regions, compute sizes, pricing, and community templates — read-only catalog.

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

      {:ok, regions} = Miosa.Regions.list_regions(client)
      {:ok, sizes} = Miosa.Regions.list_sizes(client)
  """

  alias Miosa.Client

  @doc "List available datacenter regions."
  @spec list_regions(Client.t()) :: Client.result(map())
  def list_regions(client) do
    Client.get(client, "/compute/regions")
  end

  @doc "List available compute sizes."
  @spec list_sizes(Client.t()) :: Client.result(map())
  def list_sizes(client) do
    Client.get(client, "/compute/sizes")
  end

  @doc "Get static compute pricing data."
  @spec pricing(Client.t()) :: Client.result(map())
  def pricing(client) do
    Client.get(client, "/compute/pricing")
  end

  @doc "List community computer templates."
  @spec list_templates(Client.t()) :: Client.result(map())
  def list_templates(client) do
    Client.get(client, "/compute/templates")
  end

  @doc "Get a single community template by ID."
  @spec get_template(Client.t(), String.t()) :: Client.result(map())
  def get_template(client, template_id) when is_binary(template_id) do
    Client.get(client, "/compute/templates/" <> template_id)
  end
end
