defmodule Miosa.Computer.Logs do
  @moduledoc """
  Read and stream VM logs for a computer.

    * `GET /computers/:id/logs`         — snapshot (JSON)
    * `GET /computers/:id/logs/stream`  — live SSE stream
  """

  alias Miosa.Client

  @doc """
  Fetch the most recent log snapshot (GET `/computers/:computer_id/logs`).

  ## Options

    * `:lines` — Number of log lines to return.
    * `:since` — ISO8601 timestamp; return only lines after this time.
  """
  @spec get(Client.t(), String.t(), map()) :: Client.result(map())
  def get(%Client{} = client, computer_id, opts \\ %{}) when is_binary(computer_id) do
    params = for {k, v} <- opts, v != nil, into: %{}, do: {to_string(k), v}
    req_opts = if map_size(params) > 0, do: [params: params], else: []

    client
    |> Client.get("/computers/#{computer_id}/logs", req_opts)
    |> unwrap()
  end

  @doc """
  Stream live log events via SSE (GET `/computers/:computer_id/logs/stream`).

  `callback` is called for each event map `%{type: ..., data: ...}`.
  Returns `:ok` when the stream closes or `{:error, reason}` on failure.
  """
  @spec stream(Client.t(), String.t(), function()) :: :ok | {:error, Miosa.Error.t()}
  def stream(%Client{} = client, computer_id, callback)
      when is_binary(computer_id) and is_function(callback, 1) do
    Client.stream_sse(client, "/computers/#{computer_id}/logs/stream", callback)
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap({:ok, %{"data" => data}}), do: {:ok, data}
  defp unwrap({:ok, body}), do: {:ok, body}
  defp unwrap(err), do: err
end
