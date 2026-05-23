defmodule Miosa.Computer.Osa do
  @moduledoc """
  Task dispatch to the in-VM OSA agent.

  Wraps:
    * `POST   /computers/:id/osa/task`      — submit_task/3
    * `DELETE /computers/:id/osa/task`      — cancel_task/2
    * `GET    /computers/:id/osa/status`    — status/2
    * `POST   /computers/:id/osa/configure` — configure/3
  """

  alias Miosa.Client

  @doc """
  Submit a free-form task to the in-VM OSA agent
  (POST `/computers/:computer_id/osa/task`).

  Additional params are merged into the request body.
  """
  @spec submit_task(Client.t(), String.t(), String.t(), map()) :: Client.result(map())
  def submit_task(%Client{} = client, computer_id, task, params \\ %{})
      when is_binary(computer_id) and is_binary(task) do
    body =
      params
      |> Enum.reduce(%{"task" => task}, fn {k, v}, acc ->
        if v != nil, do: Map.put(acc, to_string(k), v), else: acc
      end)

    client
    |> Client.post("/computers/#{computer_id}/osa/task", body)
    |> unwrap()
  end

  @doc """
  Cancel the currently-running OSA task, if any
  (DELETE `/computers/:computer_id/osa/task`).
  """
  @spec cancel_task(Client.t(), String.t()) :: Client.result(map())
  def cancel_task(%Client{} = client, computer_id) when is_binary(computer_id) do
    client
    |> Client.delete("/computers/#{computer_id}/osa/task")
    |> unwrap()
  end

  @doc """
  Return OSA's current task, configuration, and health snapshot
  (GET `/computers/:computer_id/osa/status`).
  """
  @spec status(Client.t(), String.t()) :: Client.result(map())
  def status(%Client{} = client, computer_id) when is_binary(computer_id) do
    client
    |> Client.get("/computers/#{computer_id}/osa/status")
    |> unwrap()
  end

  @doc """
  Update OSA runtime configuration — model, tools, secrets, etc.
  (POST `/computers/:computer_id/osa/configure`).
  """
  @spec configure(Client.t(), String.t(), map()) :: Client.result(map())
  def configure(%Client{} = client, computer_id, config) when is_binary(computer_id) do
    body = for {k, v} <- config, v != nil, into: %{}, do: {to_string(k), v}

    client
    |> Client.post("/computers/#{computer_id}/osa/configure", body)
    |> unwrap()
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap({:ok, %{"data" => data}}), do: {:ok, data}
  defp unwrap({:ok, body}), do: {:ok, body}
  defp unwrap(err), do: err
end
