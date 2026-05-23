defmodule Miosa.Sandbox.Env do
  @moduledoc """
  Per-sandbox env-var reader (GET `/sandboxes/:id/env`).

  The backend currently exposes a read-only listing. To set env vars,
  pass `env:` at sandbox creation time or via the template build-spec.
  """

  alias Miosa.Client

  @doc """
  List env vars for a sandbox (GET `/sandboxes/:sandbox_id/env`).
  """
  @spec list(Client.t(), String.t()) :: Client.result(map())
  def list(%Client{} = client, sandbox_id) when is_binary(sandbox_id) do
    case Client.get(client, "/sandboxes/#{sandbox_id}/env") do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, body} -> {:ok, body}
      err -> err
    end
  end
end
