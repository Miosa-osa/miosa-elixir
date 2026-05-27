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
  @spec list(Client.t(), String.t()) :: Client.result(list())
  def list(%Client{} = client, sandbox_id) when is_binary(sandbox_id) do
    case Client.get(client, "/sandboxes/#{sandbox_id}/env") do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, body} -> {:ok, body}
      err -> err
    end
  end

  @doc """
  Set env vars for a sandbox (PUT `/sandboxes/:sandbox_id/env`).

  `vars` is a list of maps with keys `:key`, `:value`, and optionally `:encrypted`.
  """
  @spec set(Client.t(), String.t(), list(map())) :: Client.result(map())
  def set(%Client{} = client, sandbox_id, vars)
      when is_binary(sandbox_id) and is_list(vars) do
    body = %{"vars" => vars}

    case Client.put(client, "/sandboxes/#{sandbox_id}/env", body) do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, body} -> {:ok, body}
      err -> err
    end
  end

  @doc """
  Delete a single env var from a sandbox
  (DELETE `/sandboxes/:sandbox_id/env/:key`).
  """
  @spec delete(Client.t(), String.t(), String.t()) :: Client.result(map())
  def delete(%Client{} = client, sandbox_id, key)
      when is_binary(sandbox_id) and is_binary(key) do
    Client.delete(client, "/sandboxes/#{sandbox_id}/env/#{key}")
  end
end
