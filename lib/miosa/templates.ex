defmodule Miosa.Templates do
  @moduledoc """
  Sandbox template catalog.

  Wraps `GET /api/v1/sandbox-templates`.

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))
      {:ok, templates} = Miosa.Templates.list(client)
      Enum.each(templates, &IO.inspect(&1["name"]))
  """

  alias Miosa.Client

  @doc """
  List available sandbox templates.

  Returns a list of template maps with keys:
  `"id"`, `"name"`, `"description"`, `"image_id"`, `"categories"`,
  `"default_cpu"`, `"default_memory_mb"`.
  """
  @spec list(Client.t()) :: Client.result(list(map()))
  def list(%Client{} = client) do
    case Client.get(client, "/sandbox-templates") do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, body} when is_list(body) -> {:ok, body}
      {:ok, body} -> {:ok, body}
      err -> err
    end
  end
end
