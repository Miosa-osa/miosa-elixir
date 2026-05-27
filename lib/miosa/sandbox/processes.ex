defmodule Miosa.Sandbox.Processes do
  @moduledoc """
  Background process management for a sandbox.

  Wraps:
    * `POST   /sandboxes/:id/processes`              — start/4
    * `GET    /sandboxes/:id/processes`              — list/2
    * `DELETE /sandboxes/:id/processes/:pid`         — kill/3
    * `POST   /sandboxes/:id/processes/:pid/stdin`   — send_stdin/4
  """

  alias Miosa.Client

  @doc """
  Start a background process in the sandbox
  (POST `/sandboxes/:sandbox_id/processes`).

  ## Options map keys

    * `"cwd"` — Working directory for the process.
    * `"env"` — Environment variables map.
    * `"timeout"` — Process timeout in seconds.
  """
  @spec start(Client.t(), String.t(), String.t(), map()) :: Client.result(map())
  def start(%Client{} = client, sandbox_id, command, opts \\ %{})
      when is_binary(sandbox_id) and is_binary(command) do
    body =
      opts
      |> Enum.reduce(%{"command" => command}, fn {k, v}, acc ->
        if v != nil, do: Map.put(acc, to_string(k), v), else: acc
      end)

    client
    |> Client.post("/sandboxes/#{sandbox_id}/processes", body)
    |> unwrap()
  end

  @doc """
  List all running background processes in the sandbox
  (GET `/sandboxes/:sandbox_id/processes`).
  """
  @spec list(Client.t(), String.t()) :: Client.result(list())
  def list(%Client{} = client, sandbox_id) when is_binary(sandbox_id) do
    client
    |> Client.get("/sandboxes/#{sandbox_id}/processes")
    |> unwrap()
  end

  @doc """
  Get a single process by PID
  (GET `/sandboxes/:sandbox_id/processes/:pid`).
  """
  @spec get(Client.t(), String.t(), String.t()) :: Client.result(map())
  def get(%Client{} = client, sandbox_id, pid)
      when is_binary(sandbox_id) and is_binary(pid) do
    client
    |> Client.get("/sandboxes/#{sandbox_id}/processes/#{pid}")
    |> unwrap()
  end

  @doc """
  Stop (SIGTERM → SIGKILL after 5 s) a background process by its PID
  (DELETE `/sandboxes/:sandbox_id/processes/:pid`).
  """
  @spec stop(Client.t(), String.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def stop(%Client{} = client, sandbox_id, pid)
      when is_binary(sandbox_id) and is_binary(pid) do
    case Client.delete(client, "/sandboxes/#{sandbox_id}/processes/#{pid}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @doc "Alias for `stop/3` (kept for backwards-compat)."
  @spec kill(Client.t(), String.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def kill(client, sandbox_id, pid), do: stop(client, sandbox_id, pid)

  @doc """
  Fetch the last `tail` lines of logs for a process
  (GET `/sandboxes/:sandbox_id/processes/:pid/logs?tail=N`).
  """
  @spec logs(Client.t(), String.t(), String.t(), pos_integer()) ::
          Client.result(String.t())
  def logs(%Client{} = client, sandbox_id, pid, tail \\ 200)
      when is_binary(sandbox_id) and is_binary(pid) do
    case Client.get(client, "/sandboxes/#{sandbox_id}/processes/#{pid}/logs?tail=#{tail}") do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, body} -> {:ok, body}
      err -> err
    end
  end

  @doc """
  Send data to the stdin of a running background process
  (POST `/sandboxes/:sandbox_id/processes/:pid/stdin`).
  """
  @spec send_stdin(Client.t(), String.t(), String.t(), String.t()) :: Client.result(map())
  def send_stdin(%Client{} = client, sandbox_id, pid, data)
      when is_binary(sandbox_id) and is_binary(pid) and is_binary(data) do
    body = %{"data" => data}

    client
    |> Client.post("/sandboxes/#{sandbox_id}/processes/#{pid}/stdin", body)
    |> unwrap()
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap({:ok, %{"data" => data}}), do: {:ok, data}
  defp unwrap({:ok, body}), do: {:ok, body}
  defp unwrap(err), do: err
end
