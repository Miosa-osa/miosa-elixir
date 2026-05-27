defmodule Miosa.Sandbox.Share do
  @moduledoc """
  Public share URLs for a sandbox (read-only, no API key required at the proxy).

  Wraps:
    * `POST   /sandboxes/:id/shares`            — create/3
    * `GET    /sandboxes/:id/shares`            — list/2
    * `DELETE /sandboxes/:id/shares/:share_id`  — revoke/3

  The proxy accepts the query param `?ms=<token>` to authenticate share access.
  """

  alias Miosa.Client

  @doc """
  Create a share URL for a sandbox.

  POST `/sandboxes/:sandbox_id/shares`

  ## Options
    * `:expires_in` — lifetime in seconds. Omit for no expiry.
    * `:scope`      — always `"read"` (only supported value). Defaults to `"read"`.

  Returns `{:ok, %{"share_id" => _, "share_url" => _, "expires_at" => _, "scope" => _}}`.
  """
  @spec create(Client.t(), String.t(), keyword()) :: Client.result(map())
  def create(%Client{} = client, sandbox_id, opts \\ []) when is_binary(sandbox_id) do
    body =
      %{"scope" => Keyword.get(opts, :scope, "read")}
      |> then(fn b ->
        case Keyword.get(opts, :expires_in) do
          nil -> b
          val -> Map.put(b, "expires_in", val)
        end
      end)

    case Client.post(client, "/sandboxes/#{sandbox_id}/shares", body) do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, body} -> {:ok, body}
      err -> err
    end
  end

  @doc """
  List share URLs for a sandbox.

  GET `/sandboxes/:sandbox_id/shares`
  """
  @spec list(Client.t(), String.t()) :: Client.result(list())
  def list(%Client{} = client, sandbox_id) when is_binary(sandbox_id) do
    case Client.get(client, "/sandboxes/#{sandbox_id}/shares") do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, body} -> {:ok, body}
      err -> err
    end
  end

  @doc """
  Revoke a share URL.

  DELETE `/sandboxes/:sandbox_id/shares/:share_id`
  """
  @spec revoke(Client.t(), String.t(), String.t()) :: Client.result(map())
  def revoke(%Client{} = client, sandbox_id, share_id)
      when is_binary(sandbox_id) and is_binary(share_id) do
    Client.delete(client, "/sandboxes/#{sandbox_id}/shares/#{share_id}")
  end
end
