defmodule Miosa.Sandbox.Tags do
  @moduledoc """
  Tag replacement for a sandbox (PATCH `/sandboxes/:id/tags`).
  """

  alias Miosa.Client

  @doc """
  Replace the full tag list for a sandbox
  (PATCH `/sandboxes/:sandbox_id/tags`).

  The entire tag list is replaced — not merged.
  """
  @spec set(Client.t(), String.t(), list(String.t())) :: Client.result(map())
  def set(%Client{} = client, sandbox_id, tags)
      when is_binary(sandbox_id) and is_list(tags) do
    case Client.patch(client, "/sandboxes/#{sandbox_id}/tags", %{"tags" => tags}) do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, body} -> {:ok, body}
      err -> err
    end
  end
end
