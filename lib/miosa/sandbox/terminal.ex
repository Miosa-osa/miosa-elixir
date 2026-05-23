defmodule Miosa.Sandbox.Terminal do
  @moduledoc """
  PTY session control for a sandbox.

    * `POST   /sandboxes/:id/terminal`                — create/2
    * `DELETE /sandboxes/:id/terminal/:session_id`    — delete/3
  """

  alias Miosa.Client

  @doc """
  Open a new PTY session (POST `/sandboxes/:sandbox_id/terminal`).

  ## Options map keys

    * `"cols"` — Terminal column width.
    * `"rows"` — Terminal row count.
    * `"shell"` — Shell binary path.
    * `"cwd"` — Working directory.
    * `"env"` — Environment variables map.
  """
  @spec create(Client.t(), String.t(), map()) :: Client.result(map())
  def create(%Client{} = client, sandbox_id, opts \\ %{}) when is_binary(sandbox_id) do
    body = for {k, v} <- opts, v != nil, into: %{}, do: {to_string(k), v}

    client
    |> Client.post("/sandboxes/#{sandbox_id}/terminal", body)
    |> unwrap()
  end

  @doc """
  Delete a PTY session (DELETE `/sandboxes/:sandbox_id/terminal/:session_id`).
  """
  @spec delete(Client.t(), String.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def delete(%Client{} = client, sandbox_id, session_id)
      when is_binary(sandbox_id) and is_binary(session_id) do
    case Client.delete(client, "/sandboxes/#{sandbox_id}/terminal/#{session_id}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap({:ok, %{"data" => data}}), do: {:ok, data}
  defp unwrap({:ok, body}), do: {:ok, body}
  defp unwrap(err), do: err
end
