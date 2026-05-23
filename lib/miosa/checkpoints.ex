defmodule Miosa.Checkpoints do
  @moduledoc """
  Create and restore disk snapshots (checkpoints) of MIOSA computers.

  A checkpoint captures the full disk state of a computer at a point in time.
  Restoring a checkpoint rolls the computer back to that exact state.

  ## Example

      {:ok, snap} = Miosa.Checkpoints.create(client, computer_id, %{
        name: "before-deploy"
      })

      {:ok, snaps} = Miosa.Checkpoints.list(client, computer_id)
      {:ok, snap} = Miosa.Checkpoints.get(client, computer_id, snap.id)

      # Restore with optional SSE progress streaming
      :ok = Miosa.Checkpoints.restore(client, computer_id, snap.id)

      # Stream restore progress events
      events = Miosa.Checkpoints.restore_stream(client, computer_id, snap.id)
      Enum.each(events, fn event -> IO.inspect(event) end)

      :ok = Miosa.Checkpoints.delete(client, computer_id, snap.id)

  """

  alias Miosa.{Client, Types}

  @type create_params :: %{
          optional(:name) => String.t(),
          optional(:description) => String.t()
        }

  @doc """
  Creates a new checkpoint (snapshot) of a computer's disk state.

  The computer should be stopped or in a consistent state before snapshotting.

  ## Params

    * `:name` — Optional display name.
    * `:description` — Optional description of what this snapshot represents.

  """
  @spec create(Client.t(), String.t(), create_params()) :: Client.result(Types.Snapshot.t())
  def create(%Client{} = client, computer_id, params \\ %{})
      when is_binary(computer_id) and is_map(params) do
    client
    |> Client.post("/computers/#{computer_id}/checkpoints", stringify_keys(params))
    |> unwrap_snapshot()
  end

  @doc """
  Lists all checkpoints for a computer, ordered by creation time (newest first).
  """
  @spec list(Client.t(), String.t()) :: Client.result([Types.Snapshot.t()])
  def list(%Client{} = client, computer_id) when is_binary(computer_id) do
    case Client.get(client, "/computers/#{computer_id}/checkpoints") do
      {:ok, body} ->
        snaps =
          body
          |> get_list()
          |> Enum.map(&Types.Snapshot.from_map/1)

        {:ok, snaps}

      {:error, _} = err ->
        err
    end
  end

  @doc """
  Fetches a single checkpoint by ID.
  """
  @spec get(Client.t(), String.t(), String.t()) :: Client.result(Types.Snapshot.t())
  def get(%Client{} = client, computer_id, snapshot_id)
      when is_binary(computer_id) and is_binary(snapshot_id) do
    client
    |> Client.get("/computers/#{computer_id}/checkpoints/#{snapshot_id}")
    |> unwrap_snapshot()
  end

  @doc """
  Deletes a checkpoint permanently.
  """
  @spec delete(Client.t(), String.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def delete(%Client{} = client, computer_id, snapshot_id)
      when is_binary(computer_id) and is_binary(snapshot_id) do
    client
    |> Client.delete("/computers/#{computer_id}/checkpoints/#{snapshot_id}")
    |> to_ok()
  end

  @doc """
  Restores a computer to a checkpoint state (fire-and-forget).

  The API will stop the computer (if running), restore the disk, and restart it.
  Returns `:ok` once the restore request is accepted.

  Use `restore_stream/3` to receive incremental progress events via an Elixir
  `Stream`.
  """
  @spec restore(Client.t(), String.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def restore(%Client{} = client, computer_id, snapshot_id)
      when is_binary(computer_id) and is_binary(snapshot_id) do
    client
    |> Client.post("/computers/#{computer_id}/checkpoints/#{snapshot_id}/restore")
    |> to_ok()
  end

  @doc """
  Restores a checkpoint and returns a `Stream` of progress events.

  Each element yielded by the stream is a map with at least `:event` and
  `:data` keys. The stream ends when the restore completes or fails.

  ## Example

      stream = Miosa.Checkpoints.restore_stream(client, computer_id, snap_id)
      Enum.each(stream, fn %{event: e, data: d} -> IO.puts("\#{e}: \#{inspect(d)}") end)

  """
  @spec restore_stream(Client.t(), String.t(), String.t()) :: Enumerable.t()
  def restore_stream(%Client{} = client, computer_id, snapshot_id)
      when is_binary(computer_id) and is_binary(snapshot_id) do
    path = "/computers/#{computer_id}/checkpoints/#{snapshot_id}/restore/stream"

    Stream.resource(
      fn -> start_sse(client, path) end,
      &next_sse_event/1,
      &cleanup_sse/1
    )
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap_snapshot({:ok, body}) do
    snap = body |> get_resource() |> Types.Snapshot.from_map()
    {:ok, snap}
  end

  defp unwrap_snapshot({:error, _} = err), do: err

  defp to_ok({:ok, _}), do: :ok
  defp to_ok({:error, _} = err), do: err

  defp get_resource(%{"data" => data}) when is_map(data), do: data
  defp get_resource(%{"checkpoint" => data}) when is_map(data), do: data
  defp get_resource(%{"snapshot" => data}) when is_map(data), do: data
  defp get_resource(map) when is_map(map), do: map

  defp get_list(%{"data" => list}) when is_list(list), do: list
  defp get_list(%{"checkpoints" => list}) when is_list(list), do: list
  defp get_list(%{"snapshots" => list}) when is_list(list), do: list
  defp get_list(list) when is_list(list), do: list
  defp get_list(_), do: []

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end

  # SSE stream helpers --------------------------------------------------------

  # State is one of:
  #   {:open, buffer}   — stream active, carrying an incomplete line buffer
  #   :done             — stream has completed cleanly
  #   {:error, reason}  — stream failed

  defp start_sse(client, path) do
    # Spawn an async task that drives the SSE loop and pushes events into
    # a mailbox-backed queue accessible from the stream continuation.
    parent = self()

    _task =
      Task.start(fn ->
        result =
          Client.stream_sse(client, path, fn event ->
            send(parent, {:sse_event, event})
          end)

        send(parent, {:sse_done, result})
      end)

    {:streaming, ""}
  end

  defp next_sse_event({:streaming, _buf} = state) do
    receive do
      {:sse_event, %{type: event_type, data: data_str}} ->
        parsed = parse_event_data(data_str)
        event = %{event: to_string(event_type), data: parsed}
        {[event], state}

      {:sse_done, :ok} ->
        {:halt, :done}

      {:sse_done, {:error, reason}} ->
        {:halt, {:error, reason}}
    after
      120_000 ->
        {:halt, {:error, :timeout}}
    end
  end

  defp next_sse_event(:done), do: {:halt, :done}
  defp next_sse_event({:error, _} = err), do: {:halt, err}

  defp cleanup_sse(_state), do: :ok

  defp parse_event_data(data) when is_binary(data) do
    case Jason.decode(data) do
      {:ok, map} -> map
      _ -> data
    end
  end
end
