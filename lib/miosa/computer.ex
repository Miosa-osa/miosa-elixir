defmodule Miosa.Computer do
  @moduledoc """
  Lifecycle actions for a specific MIOSA computer.

  This module covers power operations: start, stop, restart, and destroy.
  All functions require a `Miosa.Client` and a computer ID string.

  For creating and listing computers, see `Miosa.Computers`.

  ## Example

      client = Miosa.client("msk_u_...")

      :ok = Miosa.Computer.start(client, "comp_abc123")

      # Poll until running
      {:ok, computer} = Miosa.Computer.wait_until_running(client, "comp_abc123")

      :ok = Miosa.Computer.stop(client, "comp_abc123")
      :ok = Miosa.Computer.destroy(client, "comp_abc123")

  """

  alias Miosa.{Client, Types}

  @poll_interval_ms 2_000
  @default_wait_timeout_ms 300_000

  @doc """
  Starts a stopped computer.

  Returns `:ok` once the start request is accepted. The computer transitions
  through `:starting` → `:running`. Use `wait_until_running/3` to block until
  ready.
  """
  @spec start(Client.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def start(%Client{} = client, computer_id) when is_binary(computer_id) do
    client
    |> Client.post("/computers/#{computer_id}/start")
    |> to_ok()
  end

  @doc """
  Stops a running computer (graceful shutdown).

  The computer status transitions to `:stopping` → `:stopped`.
  """
  @spec stop(Client.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def stop(%Client{} = client, computer_id) when is_binary(computer_id) do
    client
    |> Client.post("/computers/#{computer_id}/stop")
    |> to_ok()
  end

  @doc """
  Restarts a running computer.

  Equivalent to stop + start. The computer will be unavailable briefly
  during the restart.
  """
  @spec restart(Client.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def restart(%Client{} = client, computer_id) when is_binary(computer_id) do
    client
    |> Client.post("/computers/#{computer_id}/restart")
    |> to_ok()
  end

  @doc """
  Destroys a computer permanently.

  This is equivalent to `Miosa.Computers.delete/2` with `force: true`.
  All data is lost. This action cannot be undone.
  """
  @spec destroy(Client.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def destroy(%Client{} = client, computer_id) when is_binary(computer_id) do
    client
    |> Client.delete("/computers/#{computer_id}", params: %{force: true})
    |> to_ok()
  end

  @doc """
  Blocks until the computer reaches `:running` status or times out.

  Polls `Miosa.Computers.get/2` every 2 seconds.

  ## Options

    * `:timeout` — Maximum wait time in milliseconds. Defaults to `300_000` (5 minutes).

  ## Returns

    * `{:ok, computer}` — when the computer is running.
    * `{:error, :timeout}` — if the computer did not reach `:running` within the timeout.
    * `{:error, reason}` — if the computer reaches `:error` status or an API error occurs.

  """
  @spec wait_until_running(Client.t(), String.t(), keyword()) ::
          {:ok, Types.Computer.t()} | {:error, :timeout | Miosa.Error.t()}
  def wait_until_running(%Client{} = client, computer_id, opts \\ [])
      when is_binary(computer_id) do
    timeout_ms = Keyword.get(opts, :timeout, @default_wait_timeout_ms)
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    poll_until_running(client, computer_id, deadline)
  end

  @doc """
  Blocks until the computer reaches `:stopped` status or times out.

  ## Options

    * `:timeout` — Maximum wait time in milliseconds. Defaults to `300_000` (5 minutes).

  """
  @spec wait_until_stopped(Client.t(), String.t(), keyword()) ::
          {:ok, Types.Computer.t()} | {:error, :timeout | Miosa.Error.t()}
  def wait_until_stopped(%Client{} = client, computer_id, opts \\ [])
      when is_binary(computer_id) do
    timeout_ms = Keyword.get(opts, :timeout, @default_wait_timeout_ms)
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    poll_until_stopped(client, computer_id, deadline)
  end

  @doc """
  Fetch the VNC/KasmVNC credentials for a computer
  (GET `/computers/:computer_id/vnc-credentials`).
  """
  @spec vnc_credentials(Client.t(), String.t()) ::
          :ok | {:error, Miosa.Error.t()} | Client.result(map())
  def vnc_credentials(%Client{} = client, computer_id) when is_binary(computer_id) do
    Client.get(client, "/computers/#{computer_id}/vnc-credentials")
  end

  @doc """
  List installed applications on a computer (GET `/computers/:computer_id/apps`).
  """
  @spec apps(Client.t(), String.t()) :: Client.result(list())
  def apps(%Client{} = client, computer_id) when is_binary(computer_id) do
    case Client.get(client, "/computers/#{computer_id}/apps") do
      {:ok, %{"data" => list}} when is_list(list) -> {:ok, list}
      {:ok, %{"apps" => list}} when is_list(list) -> {:ok, list}
      {:ok, list} when is_list(list) -> {:ok, list}
      {:ok, body} -> {:ok, body}
      err -> err
    end
  end

  @doc """
  List the named public URLs for a computer (GET `/computers/:computer_id/urls`).
  """
  @spec urls(Client.t(), String.t()) :: Client.result(map())
  def urls(%Client{} = client, computer_id) when is_binary(computer_id) do
    Client.get(client, "/computers/#{computer_id}/urls")
  end

  @doc """
  Issue a short-lived stream token for a computer
  (POST `/computers/:computer_id/stream-token`).
  """
  @spec stream_token(Client.t(), String.t()) :: Client.result(map())
  def stream_token(%Client{} = client, computer_id) when is_binary(computer_id) do
    Client.post(client, "/computers/#{computer_id}/stream-token")
  end

  @doc """
  Clone a computer into a new computer (POST `/computers/:computer_id/clone`).

  Optional `attrs` are merged into the clone creation payload.
  """
  @spec clone(Client.t(), String.t(), map()) :: Client.result(map())
  def clone(%Client{} = client, computer_id, attrs \\ %{}) when is_binary(computer_id) do
    body = for {k, v} <- attrs, v != nil, into: %{}, do: {to_string(k), v}
    Client.post(client, "/computers/#{computer_id}/clone", body)
  end

  @doc """
  Resize a computer (PATCH `/computers/:computer_id/resize`).

  Pass `cpu`, `memory_mb`, or any other size params.
  """
  @spec resize(Client.t(), String.t(), map()) :: Client.result(map())
  def resize(%Client{} = client, computer_id, attrs) when is_binary(computer_id) do
    body = for {k, v} <- attrs, v != nil, into: %{}, do: {to_string(k), v}
    Client.patch(client, "/computers/#{computer_id}/resize", body)
  end

  @doc """
  Move a computer to a different region or host
  (POST `/computers/:computer_id/move`).
  """
  @spec move(Client.t(), String.t(), map()) :: Client.result(map())
  def move(%Client{} = client, computer_id, attrs) when is_binary(computer_id) do
    body = for {k, v} <- attrs, v != nil, into: %{}, do: {to_string(k), v}
    Client.post(client, "/computers/#{computer_id}/move", body)
  end

  @doc """
  Take a screenshot of a sub-region
  (GET `/computers/:computer_id/screenshot`).

  Coordinates are in 0–1000 space (MIOSA canonical coordinate system).
  Returns raw PNG binary.
  """
  @spec screenshot_region(Client.t(), String.t(), integer(), integer(), integer(), integer()) ::
          Client.result(binary())
  def screenshot_region(%Client{} = client, computer_id, x, y, width, height)
      when is_binary(computer_id) do
    Client.get_binary(client, "/computers/#{computer_id}/screenshot",
      params: %{x: x, y: y, width: width, height: height}
    )
  end

  @doc """
  Returns the preview URL for a specific port on the computer.

  The preview URL provides authenticated HTTP access to a service running inside
  the computer. Append a path after the returned URL as needed.

  ## Parameters

    * `computer_id` — Computer ID string.
    * `port` — Port number the service is listening on inside the VM.
    * `opts`:
      * `:base_url` — Override the base domain. Defaults to `"https://preview.miosa.ai"`.

  ## Example

      url = Miosa.Computer.preview_url(client, "comp_abc", 3000)
      # => "https://preview.miosa.ai/comp_abc/3000"

  """
  @spec preview_url(Client.t(), String.t(), pos_integer(), keyword()) :: String.t()
  def preview_url(%Client{} = client, computer_id, port, opts \\ [])
      when is_binary(computer_id) and is_integer(port) do
    base = Keyword.get(opts, :base_url, "https://preview.miosa.ai")
    _ = client
    "#{base}/#{computer_id}/#{port}"
  end

  @doc """
  Returns the public URL for the computer desktop stream.

  This URL is the root access point for the computer's web interface
  (VNC/KasmVNC). Requires the computer to be running and `:visibility`
  set to `:public` or authenticated with an API key.

  ## Example

      url = Miosa.Computer.public_url(client, "comp_abc")
      # => "https://desktop.miosa.ai/comp_abc"

  """
  @spec public_url(Client.t(), String.t(), keyword()) :: String.t()
  def public_url(%Client{} = client, computer_id, opts \\ []) when is_binary(computer_id) do
    base = Keyword.get(opts, :base_url, "https://desktop.miosa.ai")
    _ = client
    "#{base}/#{computer_id}"
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp to_ok({:ok, _}), do: :ok
  defp to_ok({:error, _} = err), do: err

  defp poll_until_running(client, computer_id, deadline) do
    case Miosa.Computers.get(client, computer_id) do
      {:ok, %Types.Computer{status: :running} = computer} ->
        {:ok, computer}

      {:ok, %Types.Computer{status: :error}} ->
        {:error,
         %Miosa.Error{
           message: "Computer entered error state",
           status: nil,
           code: "COMPUTER_ERROR"
         }}

      {:ok, _} ->
        if past_deadline?(deadline) do
          {:error, :timeout}
        else
          Process.sleep(@poll_interval_ms)
          poll_until_running(client, computer_id, deadline)
        end

      {:error, _} = err ->
        err
    end
  end

  defp poll_until_stopped(client, computer_id, deadline) do
    case Miosa.Computers.get(client, computer_id) do
      {:ok, %Types.Computer{status: :stopped} = computer} ->
        {:ok, computer}

      {:ok, %Types.Computer{status: :error}} ->
        {:error,
         %Miosa.Error{
           message: "Computer entered error state",
           status: nil,
           code: "COMPUTER_ERROR"
         }}

      {:ok, _} ->
        if past_deadline?(deadline) do
          {:error, :timeout}
        else
          Process.sleep(@poll_interval_ms)
          poll_until_stopped(client, computer_id, deadline)
        end

      {:error, _} = err ->
        err
    end
  end

  defp past_deadline?(deadline), do: System.monotonic_time(:millisecond) >= deadline
end
