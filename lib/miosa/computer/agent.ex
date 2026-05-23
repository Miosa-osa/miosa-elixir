defmodule Miosa.Computer.Agent do
  @moduledoc """
  Computer-Use Agent (CUA) session management for a computer.

  Wraps:
    * `POST   /computers/:id/cua/sessions`          — run/4
    * `GET    /computers/:id/cua/sessions`          — list/2
    * `GET    /computers/:id/cua/sessions/:sid`     — get/3
    * `DELETE /computers/:id/cua/sessions/:sid`     — cancel/3
  """

  alias Miosa.Client

  @doc """
  Create and start a CUA session for a computer
  (POST `/computers/:computer_id/cua/sessions`).

  ## Options map keys

    * `"model"` — Override the AI model (e.g. `"claude-3-5-sonnet-latest"`).
    * `"max_steps"` — Maximum number of agent steps before stopping.
    * `"tools"` — List of additional tool names to enable.
    * `"timeout"` — Session timeout in seconds.
  """
  @spec run(Client.t(), String.t(), String.t(), map()) :: Client.result(map())
  def run(%Client{} = client, computer_id, goal, opts \\ %{})
      when is_binary(computer_id) and is_binary(goal) do
    body =
      opts
      |> Enum.reduce(%{"goal" => goal}, fn {k, v}, acc ->
        if v != nil, do: Map.put(acc, to_string(k), v), else: acc
      end)

    client
    |> Client.post("/computers/#{computer_id}/cua/sessions", body)
    |> unwrap()
  end

  @doc """
  List all CUA sessions for a computer
  (GET `/computers/:computer_id/cua/sessions`).
  """
  @spec list(Client.t(), String.t()) :: Client.result(list())
  def list(%Client{} = client, computer_id) when is_binary(computer_id) do
    client
    |> Client.get("/computers/#{computer_id}/cua/sessions")
    |> unwrap()
  end

  @doc """
  Retrieve a single CUA session by ID
  (GET `/computers/:computer_id/cua/sessions/:session_id`).
  """
  @spec get(Client.t(), String.t(), String.t()) :: Client.result(map())
  def get(%Client{} = client, computer_id, session_id)
      when is_binary(computer_id) and is_binary(session_id) do
    client
    |> Client.get("/computers/#{computer_id}/cua/sessions/#{session_id}")
    |> unwrap()
  end

  @doc """
  Cancel a running CUA session
  (DELETE `/computers/:computer_id/cua/sessions/:session_id`).
  """
  @spec cancel(Client.t(), String.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def cancel(%Client{} = client, computer_id, session_id)
      when is_binary(computer_id) and is_binary(session_id) do
    case Client.delete(client, "/computers/#{computer_id}/cua/sessions/#{session_id}") do
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
