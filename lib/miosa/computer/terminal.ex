defmodule Miosa.Computer.Terminal do
  @moduledoc """
  PTY session management for a computer.

  Maps to `POST /computers/:id/terminal` (create) and
  `POST /computers/:id/pty/:session_id/resize` (resize).
  """

  alias Miosa.Client

  @doc """
  Open a new PTY session (POST `/computers/:computer_id/terminal`).

  ## Options

    * `:cols` — Terminal column width.
    * `:rows` — Terminal row count.
    * `:shell` — Shell binary path (e.g. `"/bin/bash"`).
    * `:cwd` — Working directory inside the VM.
    * `:env` — Environment variables map.
  """
  @spec create(Client.t(), String.t(), map()) :: Client.result(map())
  def create(%Client{} = client, computer_id, opts \\ %{}) when is_binary(computer_id) do
    body = for {k, v} <- opts, v != nil, into: %{}, do: {to_string(k), v}

    client
    |> Client.post("/computers/#{computer_id}/terminal", body)
    |> unwrap()
  end

  @doc """
  Resize an existing PTY session
  (POST `/computers/:computer_id/pty/:session_id/resize`).
  """
  @spec resize(Client.t(), String.t(), String.t(), pos_integer(), pos_integer()) ::
          Client.result(map())
  def resize(%Client{} = client, computer_id, session_id, cols, rows)
      when is_binary(computer_id) and is_binary(session_id) and is_integer(cols) and
             is_integer(rows) do
    body = %{"cols" => cols, "rows" => rows}

    client
    |> Client.post("/computers/#{computer_id}/pty/#{session_id}/resize", body)
    |> unwrap()
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap({:ok, %{"data" => data}}), do: {:ok, data}
  defp unwrap({:ok, body}), do: {:ok, body}
  defp unwrap(err), do: err
end
