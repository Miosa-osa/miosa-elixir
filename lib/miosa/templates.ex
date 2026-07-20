defmodule Miosa.Templates do
  @moduledoc """
  Canonical product template catalog.

  Wraps `GET /api/v1/templates` and exposes read-only product/template/size
  readiness metadata across sandboxes, computers, and Docker Deploy appliance
  hosts.

  Use `Miosa.SandboxTemplates` for tenant-owned custom sandbox template CRUD and
  builds.

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))
      {:ok, templates} = Miosa.Templates.list(client)
      Enum.each(templates, &IO.inspect(&1["id"]))
  """

  alias Miosa.Client

  @doc """
  Return the full product/template/size catalog.
  """
  @spec catalog(Client.t()) :: Client.result(map())
  def catalog(%Client{} = client) do
    Client.get(client, "/templates")
  end

  @doc """
  List canonical product templates.

  Options:
    * `:product` - Optional product filter: `"sandbox"`, `"computer"`, or
      `"docker_deploy_host"`.
  """
  @spec list(Client.t(), keyword() | map()) :: Client.result(list(map()))
  def list(%Client{} = client, opts \\ []) do
    filters = normalize(opts)
    product = Map.get(filters, :product) || Map.get(filters, "product")

    with {:ok, catalog} <- catalog(client) do
      templates = product_templates(catalog)

      templates =
        if product do
          Enum.filter(templates, &(&1["product"] == product))
        else
          templates
        end

      {:ok, templates}
    end
  end

  @doc "Fetch one canonical product template by ID."
  @spec get(Client.t(), String.t()) :: Client.result(map())
  def get(%Client{} = client, template_id) when is_binary(template_id) do
    with {:ok, templates} <- list(client) do
      case Enum.find(templates, &(&1["id"] == template_id)) do
        nil ->
          {:error,
           %Miosa.Error{
             status: 404,
             code: "NOT_FOUND",
             message: "template not found: #{template_id}",
             body: nil
           }}

        template ->
          {:ok, template}
      end
    end
  end

  @doc "Return size-readiness rows for one canonical product template."
  @spec readiness(Client.t(), String.t()) :: Client.result(list(map()))
  def readiness(%Client{} = client, template_id) when is_binary(template_id) do
    with {:ok, template} <- get(client, template_id) do
      {:ok, Map.get(template, "sizes", [])}
    end
  end

  defp product_templates(%{"data" => %{"templates" => templates}}) when is_list(templates),
    do: templates

  defp product_templates(%{"templates" => templates}) when is_list(templates),
    do: templates

  defp product_templates(templates) when is_list(templates),
    do: templates

  defp product_templates(_),
    do: []

  defp normalize(filters) when is_list(filters), do: Map.new(filters)
  defp normalize(filters) when is_map(filters), do: filters
end
