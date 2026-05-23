defmodule Miosa.Services do
  @moduledoc """
  Manage long-running background services inside a MIOSA computer.

  A service is a supervised process (e.g. a web server, a database, a worker)
  that runs inside the VM and can be started, stopped, restarted, and observed
  via a log stream.

  ## Example

      {:ok, svc} = Miosa.Services.create(client, computer_id, %{
        name: "web",
        command: "python -m http.server 8080",
        working_dir: "/home/user/app"
      })

      :ok = Miosa.Services.start(client, computer_id, svc.id)
      :ok = Miosa.Services.stop(client, computer_id, svc.id)
      :ok = Miosa.Services.restart(client, computer_id, svc.id)

      # Tail logs as a Stream
      log_stream = Miosa.Services.logs(client, computer_id, svc.id)
      Enum.each(log_stream, fn %Miosa.Types.ServiceLogEvent{line: l} -> IO.puts(l) end)

      :ok = Miosa.Services.delete(client, computer_id, svc.id)

  """

  alias Miosa.{Client, Types}

  @type create_params :: %{
          required(:name) => String.t(),
          required(:command) => String.t(),
          optional(:working_dir) => String.t(),
          optional(:env) => map(),
          optional(:auto_restart) => boolean()
        }

  @doc """
  Creates a new service definition inside a computer.

  ## Params

    * `:name` — Required. Unique name for the service within this computer.
    * `:command` — Required. Shell command to run.
    * `:working_dir` — Working directory. Defaults to `"/home/user"`.
    * `:env` — Map of additional environment variables.
    * `:auto_restart` — Restart on crash. Defaults to `false`.

  """
  @spec create(Client.t(), String.t(), create_params()) :: Client.result(Types.Service.t())
  def create(%Client{} = client, computer_id, params)
      when is_binary(computer_id) and is_map(params) do
    client
    |> Client.post("/computers/#{computer_id}/services", stringify_keys(params))
    |> unwrap_service()
  end

  @doc """
  Lists all services for a computer.
  """
  @spec list(Client.t(), String.t()) :: Client.result([Types.Service.t()])
  def list(%Client{} = client, computer_id) when is_binary(computer_id) do
    case Client.get(client, "/computers/#{computer_id}/services") do
      {:ok, body} ->
        services =
          body
          |> get_list()
          |> Enum.map(&Types.Service.from_map/1)

        {:ok, services}

      {:error, _} = err ->
        err
    end
  end

  @doc """
  Fetches a single service by ID.
  """
  @spec get(Client.t(), String.t(), String.t()) :: Client.result(Types.Service.t())
  def get(%Client{} = client, computer_id, service_id)
      when is_binary(computer_id) and is_binary(service_id) do
    client
    |> Client.get("/computers/#{computer_id}/services/#{service_id}")
    |> unwrap_service()
  end

  @doc """
  Starts a service.
  """
  @spec start(Client.t(), String.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def start(%Client{} = client, computer_id, service_id)
      when is_binary(computer_id) and is_binary(service_id) do
    client
    |> Client.post("/computers/#{computer_id}/services/#{service_id}/start")
    |> to_ok()
  end

  @doc """
  Stops a running service.
  """
  @spec stop(Client.t(), String.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def stop(%Client{} = client, computer_id, service_id)
      when is_binary(computer_id) and is_binary(service_id) do
    client
    |> Client.post("/computers/#{computer_id}/services/#{service_id}/stop")
    |> to_ok()
  end

  @doc """
  Restarts a service (stop + start).
  """
  @spec restart(Client.t(), String.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def restart(%Client{} = client, computer_id, service_id)
      when is_binary(computer_id) and is_binary(service_id) do
    client
    |> Client.post("/computers/#{computer_id}/services/#{service_id}/restart")
    |> to_ok()
  end

  @doc """
  Deletes a service definition.

  The service must be stopped before deletion.
  """
  @spec delete(Client.t(), String.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def delete(%Client{} = client, computer_id, service_id)
      when is_binary(computer_id) and is_binary(service_id) do
    client
    |> Client.delete("/computers/#{computer_id}/services/#{service_id}")
    |> to_ok()
  end

  @doc """
  Returns a `Stream` of `Miosa.Types.ServiceLogEvent` structs for a service.

  The stream tails the service's stdout/stderr in real time via SSE. It
  completes when the server closes the connection or the service exits.

  ## Options

    * `:follow` — Continue streaming after the service exits until the
      connection is closed. Defaults to `true`.
    * `:tail` — Number of historical lines to include before live output.
      Defaults to `0` (live only).

  ## Example

      Miosa.Services.logs(client, computer_id, service_id)
      |> Stream.each(fn %{line: l} -> IO.puts(l) end)
      |> Stream.run()

  """
  @spec logs(Client.t(), String.t(), String.t(), keyword()) ::
          Enumerable.t()
  def logs(%Client{} = client, computer_id, service_id, opts \\ [])
      when is_binary(computer_id) and is_binary(service_id) do
    follow = Keyword.get(opts, :follow, true)
    tail = Keyword.get(opts, :tail, 0)

    params =
      %{}
      |> maybe_put("follow", follow)
      |> maybe_put("tail", tail)

    query = URI.encode_query(params)
    path = "/computers/#{computer_id}/services/#{service_id}/logs?#{query}"

    parent = self()

    Stream.resource(
      fn ->
        Task.start(fn ->
          result =
            Client.stream_sse(client, path, fn event ->
              send(parent, {:log_event, event})
            end)

          send(parent, {:log_done, result})
        end)

        :streaming
      end,
      fn state ->
        case state do
          :streaming ->
            receive do
              {:log_event, %{data: data_str}} ->
                log_event = parse_log_event(data_str)
                {[log_event], :streaming}

              {:log_done, :ok} ->
                {:halt, :done}

              {:log_done, {:error, reason}} ->
                {:halt, {:error, reason}}
            after
              300_000 ->
                {:halt, {:error, :timeout}}
            end

          _ ->
            {:halt, state}
        end
      end,
      fn _state -> :ok end
    )
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap_service({:ok, body}) do
    svc = body |> get_resource() |> Types.Service.from_map()
    {:ok, svc}
  end

  defp unwrap_service({:error, _} = err), do: err

  defp to_ok({:ok, _}), do: :ok
  defp to_ok({:error, _} = err), do: err

  defp get_resource(%{"data" => data}) when is_map(data), do: data
  defp get_resource(%{"service" => data}) when is_map(data), do: data
  defp get_resource(map) when is_map(map), do: map

  defp get_list(%{"data" => list}) when is_list(list), do: list
  defp get_list(%{"services" => list}) when is_list(list), do: list
  defp get_list(list) when is_list(list), do: list
  defp get_list(_), do: []

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp parse_log_event(data) when is_binary(data) do
    case Jason.decode(data) do
      {:ok, map} -> Types.ServiceLogEvent.from_map(map)
      _ -> %Types.ServiceLogEvent{line: data, stream: "stdout"}
    end
  end
end
