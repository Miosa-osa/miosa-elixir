defmodule Miosa.Exec do
  @moduledoc """
  Execute commands and scripts inside a running MIOSA computer.

  Both Bash and Python execution are supported. Commands run with the default
  user's environment inside the VM.

  ## Example

      {:ok, result} = Miosa.Exec.bash(client, computer_id, "ls -la /home/user")
      IO.puts(result.output)
      IO.puts("Exit code: \#{result.exit_code}")

      {:ok, result} = Miosa.Exec.python(client, computer_id, \"\"\"
        import json
        data = {"hello": "world"}
        print(json.dumps(data))
      \"\"\")

  """

  alias Miosa.{Client, Types}

  @doc """
  Executes a Bash command inside the computer.

  ## Options

    * `:timeout` — Execution timeout in milliseconds. Defaults to `30_000`.
    * `:working_dir` — Working directory for the command. Defaults to `"/home/user"`.
    * `:env` — Map of additional environment variables.

  ## Returns

  `{:ok, result}` with an `ExecResult` containing `:output`, `:stdout`,
  `:stderr`, and `:exit_code`. On API error, returns `{:error, reason}`.
  """
  @spec bash(Client.t(), String.t(), String.t(), keyword()) ::
          Client.result(Types.ExecResult.t())
  def bash(%Client{} = client, computer_id, command, opts \\ [])
      when is_binary(command) do
    body = build_body(%{command: command}, opts)

    client
    |> Client.post("/computers/#{computer_id}/exec", body)
    |> unwrap_result()
  end

  @doc """
  Executes a Python script inside the computer.

  The script runs with the system Python 3 interpreter. Common packages
  (requests, numpy, pandas, etc.) may be pre-installed depending on the
  computer template.

  ## Options

    * `:timeout` — Execution timeout in milliseconds. Defaults to `30_000`.
    * `:working_dir` — Working directory. Defaults to `"/home/user"`.
    * `:env` — Map of additional environment variables.

  """
  @spec python(Client.t(), String.t(), String.t(), keyword()) ::
          Client.result(Types.ExecResult.t())
  def python(%Client{} = client, computer_id, code, opts \\ [])
      when is_binary(code) do
    body = build_body(%{code: code}, opts)

    client
    |> Client.post("/computers/#{computer_id}/exec/python", body)
    |> unwrap_result()
  end

  @doc """
  Convenience wrapper: runs bash and raises `Miosa.Error` on failure.

  Returns the `ExecResult` directly (not wrapped in `{:ok, _}`).
  """
  @spec bash!(Client.t(), String.t(), String.t(), keyword()) :: Types.ExecResult.t()
  def bash!(%Client{} = client, computer_id, command, opts \\ []) do
    case bash(client, computer_id, command, opts) do
      {:ok, result} -> result
      {:error, err} -> raise err
    end
  end

  @doc """
  Convenience wrapper: runs python and raises `Miosa.Error` on failure.

  Returns the `ExecResult` directly (not wrapped in `{:ok, _}`).
  """
  @spec python!(Client.t(), String.t(), String.t(), keyword()) :: Types.ExecResult.t()
  def python!(%Client{} = client, computer_id, code, opts \\ []) do
    case python(client, computer_id, code, opts) do
      {:ok, result} -> result
      {:error, err} -> raise err
    end
  end

  @doc """
  Spawns an interactive command session over WebSocket and returns a
  `Miosa.Exec.Command` GenServer PID.

  The returned PID represents a live WebSocket connection to the computer.
  Use `Miosa.Exec.Command.send_stdin/2`, `close_stdin/1`, `resize/3`, and
  `await/2` to interact with the running process.

  The GenServer owns the WebSocket connection and terminates it on shutdown.
  Callers should always call `Miosa.Exec.Command.await/2` to drain the session
  and ensure the underlying connection is cleaned up.

  ## Options

    * `:pty` — Allocate a pseudo-terminal. Required for interactive programs
      like shells. Defaults to `false`.

  ## Example

      {:ok, cmd} = Miosa.Exec.spawn(client, computer_id, "bash", pty: true)
      :ok = Miosa.Exec.Command.send_stdin(cmd, "echo hello\\n")
      :ok = Miosa.Exec.Command.send_stdin(cmd, "exit\\n")
      {:ok, 0} = Miosa.Exec.Command.await(cmd, 5_000)

  """
  @spec spawn(Client.t(), String.t(), String.t(), keyword()) ::
          {:ok, Miosa.Exec.Command.t()} | {:error, term()}
  def spawn(%Client{} = client, computer_id, command, opts \\ [])
      when is_binary(computer_id) and is_binary(command) do
    Miosa.Exec.Command.start_link(
      client: client,
      computer_id: computer_id,
      command: command,
      pty: Keyword.get(opts, :pty, false)
    )
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp build_body(base, opts) do
    base
    |> maybe_put(:timeout, Keyword.get(opts, :timeout))
    |> maybe_put(:working_dir, Keyword.get(opts, :working_dir))
    |> maybe_put(:env, Keyword.get(opts, :env))
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp unwrap_result({:ok, body}) do
    result = body |> get_resource() |> Types.ExecResult.from_map()
    {:ok, result}
  end

  defp unwrap_result({:error, _} = err), do: err

  defp get_resource(%{"data" => data}) when is_map(data), do: data
  defp get_resource(%{"result" => data}) when is_map(data), do: data
  defp get_resource(map) when is_map(map), do: map
end
