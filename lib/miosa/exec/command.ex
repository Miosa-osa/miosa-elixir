defmodule Miosa.Exec.Command do
  @moduledoc """
  A GenServer holding a long-lived interactive command session over WebSocket.

  Obtained via `Miosa.Exec.spawn/3`. Provides stdin/stdout interaction and
  terminal resize for PTY-based commands.

  The underlying WebSocket is managed via `:gun`. The GenServer owns the
  connection and shuts it down on termination.

  ## Example

      {:ok, cmd} = Miosa.Exec.spawn(client, computer_id, "bash")

      :ok = Miosa.Exec.Command.send_stdin(cmd, "ls -la\\n")
      :ok = Miosa.Exec.Command.resize(cmd, 120, 40)

      # Block until the command exits (or timeout)
      {:ok, exit_code} = Miosa.Exec.Command.await(cmd, 30_000)

  """

  use GenServer
  require Logger

  @default_await_timeout 30_000

  defstruct [
    :client,
    :computer_id,
    :command,
    :gun_pid,
    :stream_ref,
    :status,
    :exit_code,
    :output_buffer,
    :waiters
  ]

  @type t :: pid()

  # ---------------------------------------------------------------------------
  # Client API
  # ---------------------------------------------------------------------------

  @doc """
  Sends data to the command's stdin.

  `data` should be a binary string (may include newlines).
  Returns `:ok` immediately; delivery is async over the WebSocket.
  """
  @spec send_stdin(t(), String.t()) :: :ok | {:error, term()}
  def send_stdin(pid, data) when is_pid(pid) and is_binary(data) do
    GenServer.call(pid, {:send_stdin, data})
  end

  @doc """
  Signals stdin EOF to the command (closes the write half of the WebSocket).
  """
  @spec close_stdin(t()) :: :ok | {:error, term()}
  def close_stdin(pid) when is_pid(pid) do
    GenServer.call(pid, :close_stdin)
  end

  @doc """
  Sends a terminal resize event (SIGWINCH) to the running command.

  Only meaningful for PTY-based commands (those started with `pty: true`).
  """
  @spec resize(t(), pos_integer(), pos_integer()) :: :ok | {:error, term()}
  def resize(pid, cols, rows) when is_pid(pid) and is_integer(cols) and is_integer(rows) do
    GenServer.call(pid, {:resize, cols, rows})
  end

  @doc """
  Blocks until the command exits and returns `{:ok, exit_code}`.

  Returns `{:error, :timeout}` if the command does not exit within `timeout_ms`.
  The GenServer process is stopped after `await/2` returns.
  """
  @spec await(t(), pos_integer()) :: {:ok, integer()} | {:error, :timeout | term()}
  def await(pid, timeout_ms \\ @default_await_timeout) when is_pid(pid) do
    try do
      GenServer.call(pid, :await, timeout_ms)
    catch
      :exit, {:timeout, _} -> {:error, :timeout}
    end
  end

  # ---------------------------------------------------------------------------
  # GenServer lifecycle
  # ---------------------------------------------------------------------------

  @doc false
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    client = Keyword.fetch!(opts, :client)
    computer_id = Keyword.fetch!(opts, :computer_id)
    command = Keyword.fetch!(opts, :command)
    pty = Keyword.get(opts, :pty, false)

    state = %__MODULE__{
      client: client,
      computer_id: computer_id,
      command: command,
      status: :connecting,
      exit_code: nil,
      output_buffer: [],
      waiters: []
    }

    # Connect asynchronously so init does not block the caller.
    send(self(), {:connect, pty})
    {:ok, state}
  end

  @impl true
  def handle_info({:connect, pty}, state) do
    %__MODULE__{client: client, computer_id: cid, command: command} = state

    ws_url = build_ws_url(client, cid, command, pty)

    case open_gun_ws(ws_url) do
      {:ok, gun_pid, stream_ref} ->
        {:noreply, %{state | gun_pid: gun_pid, stream_ref: stream_ref, status: :running}}

      {:error, reason} ->
        Logger.error("[Miosa.Exec.Command] WebSocket connect failed: #{inspect(reason)}")
        {:stop, {:ws_connect_failed, reason}, state}
    end
  end

  # Receive text frame from the server (stdout/stderr data).
  def handle_info({:gun_ws, _gun, _stream, {:text, data}}, state) do
    new_buffer = [data | state.output_buffer]
    {:noreply, %{state | output_buffer: new_buffer}}
  end

  # Binary frame (raw stdout bytes).
  def handle_info({:gun_ws, _gun, _stream, {:binary, data}}, state) do
    new_buffer = [data | state.output_buffer]
    {:noreply, %{state | output_buffer: new_buffer}}
  end

  # WebSocket close frame — command exited.
  def handle_info({:gun_ws, _gun, _stream, {:close, code, _reason}}, state) do
    exit_code = if code in 1000..1999, do: code - 1000, else: 0
    new_state = %{state | status: :done, exit_code: exit_code}
    reply_waiters(new_state)
    {:stop, :normal, new_state}
  end

  # gun connection down.
  def handle_info({:gun_down, _gun, _proto, reason, _streams}, state) do
    Logger.warning("[Miosa.Exec.Command] gun connection down: #{inspect(reason)}")
    new_state = %{state | status: :error, exit_code: -1}
    reply_waiters(new_state)
    {:stop, {:gun_down, reason}, new_state}
  end

  def handle_info(_msg, state), do: {:noreply, state}

  @impl true
  def handle_call({:send_stdin, data}, _from, %{status: :running} = state) do
    :gun.ws_send(state.gun_pid, state.stream_ref, {:text, data})
    {:reply, :ok, state}
  end

  def handle_call({:send_stdin, _data}, _from, state) do
    {:reply, {:error, :not_running}, state}
  end

  def handle_call(:close_stdin, _from, %{status: :running} = state) do
    :gun.ws_send(state.gun_pid, state.stream_ref, :close)
    {:reply, :ok, state}
  end

  def handle_call(:close_stdin, _from, state) do
    {:reply, {:error, :not_running}, state}
  end

  def handle_call({:resize, cols, rows}, _from, %{status: :running} = state) do
    payload = Jason.encode!(%{"type" => "resize", "cols" => cols, "rows" => rows})
    :gun.ws_send(state.gun_pid, state.stream_ref, {:text, payload})
    {:reply, :ok, state}
  end

  def handle_call({:resize, _cols, _rows}, _from, state) do
    {:reply, {:error, :not_running}, state}
  end

  def handle_call(:await, _from, %{status: :done} = state) do
    {:stop, :normal, {:ok, state.exit_code || 0}, state}
  end

  def handle_call(:await, from, state) do
    # Park the caller; reply when we receive the close frame.
    {:noreply, %{state | waiters: [from | state.waiters]}}
  end

  @impl true
  def terminate(_reason, %{gun_pid: gun_pid}) when is_pid(gun_pid) do
    :gun.close(gun_pid)
    :ok
  end

  def terminate(_reason, _state), do: :ok

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp reply_waiters(%{waiters: waiters, exit_code: code}) do
    Enum.each(waiters, fn from ->
      GenServer.reply(from, {:ok, code || 0})
    end)
  end

  defp build_ws_url(client, computer_id, command, pty) do
    encoded_cmd = URI.encode_www_form(command)
    pty_param = if pty, do: "&pty=true", else: ""
    base = String.replace(client.base_url, ~r|^https?|, "ws")
    "#{base}/computers/#{computer_id}/exec/ws?command=#{encoded_cmd}#{pty_param}"
  end

  defp open_gun_ws(ws_url) do
    uri = URI.parse(ws_url)
    host = String.to_charlist(uri.host)
    port = uri.port || 443
    transport = if uri.scheme == "wss", do: :tls, else: :tcp

    opts = %{
      transport: transport,
      protocols: [:http]
    }

    with {:ok, gun_pid} <- :gun.open(host, port, opts),
         {:ok, _protocol} <- :gun.await_up(gun_pid, 5_000),
         stream_ref = :gun.ws_upgrade(gun_pid, uri.path || "/"),
         :ok <- await_ws_upgrade(gun_pid, stream_ref) do
      {:ok, gun_pid, stream_ref}
    end
  end

  defp await_ws_upgrade(gun_pid, stream_ref) do
    receive do
      {:gun_upgrade, ^gun_pid, ^stream_ref, ["websocket"], _headers} ->
        :ok

      {:gun_response, ^gun_pid, _ref, _fin, status, _headers} ->
        {:error, {:http_error, status}}

      {:gun_error, ^gun_pid, ^stream_ref, reason} ->
        {:error, reason}
    after
      10_000 -> {:error, :upgrade_timeout}
    end
  end
end
