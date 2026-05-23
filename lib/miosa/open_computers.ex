defmodule Miosa.OpenComputers do
  @moduledoc """
  OpenComputers API surface — register and control your own machines via MIOSA.

  OpenComputers lets you bring your own Mac, Linux, or Windows machine and
  control it through the MIOSA API: run commands, manage files, expose HTTP
  tunnels, dispatch AI agents, build inference clusters, and manage secrets.

  ## Entry points

  All functions accept a `Miosa.Client.t()` as the first argument:

      client = Miosa.client("msk_u_...")

      # Hosts
      {:ok, resp} = Miosa.OpenComputers.Hosts.list(client)
      {:ok, host} = Miosa.OpenComputers.Hosts.create(client, %{name: "my-mac"})

      # Jobs
      {:ok, job} = Miosa.OpenComputers.Jobs.run(client, host["id"], %{command: "npm test"})

      # Tunnels
      {:ok, tunnel} = Miosa.OpenComputers.Tunnels.create(client, host["id"], %{target_port: 3000})
      IO.puts(tunnel["public_url"])

      # Agents
      {:ok, session} = Miosa.OpenComputers.Agents.dispatch(client, host["id"], %{task: "run tests"})

  """
end

defmodule Miosa.OpenComputers.Hosts do
  @moduledoc """
  Host registration and lifecycle.

  A **host** is a physical or virtual machine you own that has been registered
  with MIOSA by installing the `miosa-host` agent. Once registered, MIOSA can
  dispatch jobs, manage files, issue tunnels, and run AI agents on it.

  The `host_key` is returned **only on creation** — save it immediately.
  """

  alias Miosa.Client

  @type result :: {:ok, map()} | {:error, Miosa.Error.t()}

  @doc """
  List all registered hosts.

  Options: `:page`, `:per_page`.
  """
  @spec list(Client.t(), keyword()) :: result()
  def list(client, opts \\ []) do
    params = pick(opts, [:page, :per_page])
    Client.get(client, "/opencomputers/hosts", params: params)
  end

  @doc """
  Register a new host.

  `attrs` must include `:name`. Optional: `:region`, `:labels`.

  The returned map includes `host_key` — shown **once**, store it securely.
  """
  @spec create(Client.t(), map()) :: result()
  def create(client, attrs) when is_map(attrs) do
    Client.post(client, "/opencomputers/hosts", attrs)
  end

  @doc "Get a host by ID."
  @spec get(Client.t(), String.t()) :: result()
  def get(client, host_id), do: Client.get(client, "/opencomputers/hosts/#{host_id}")

  @doc "Update host metadata (name, labels)."
  @spec update(Client.t(), String.t(), map()) :: result()
  def update(client, host_id, attrs) when is_map(attrs) do
    Client.patch(client, "/opencomputers/hosts/#{host_id}", attrs)
  end

  @doc "Revoke a host registration. The host loses access immediately."
  @spec revoke(Client.t(), String.t()) :: result()
  def revoke(client, host_id), do: Client.delete(client, "/opencomputers/hosts/#{host_id}")

  @doc """
  Stream live host events (SSE).

  The `callback` is called for each `%{type: type, data: data}` event map.
  Blocks until the stream ends. Returns `:ok` or `{:error, reason}`.
  """
  @spec events(Client.t(), String.t(), function()) :: :ok | {:error, Miosa.Error.t()}
  def events(client, host_id, callback) when is_function(callback, 1) do
    Client.stream_sse(client, "/opencomputers/hosts/#{host_id}/events", callback)
  end

  defp pick(opts, keys) do
    opts |> Keyword.take(keys) |> Enum.reject(fn {_, v} -> is_nil(v) end)
  end
end

defmodule Miosa.OpenComputers.Jobs do
  @moduledoc """
  Remote job execution on registered hosts.

  Jobs dispatch shell commands to a registered host and return the result once
  the command completes.
  """

  alias Miosa.Client

  @type result :: {:ok, map()} | {:error, Miosa.Error.t()}

  @doc """
  Run a command on a host and return the completed job.

  `attrs` must include `:command`. Optional: `:args`, `:env`, `:cwd`, `:timeout`.
  """
  @spec run(Client.t(), String.t(), map()) :: result()
  def run(client, host_id, attrs) when is_map(attrs) do
    Client.post(client, "/opencomputers/hosts/#{host_id}/exec", attrs)
  end

  @doc "List jobs for a host."
  @spec list(Client.t(), String.t(), keyword()) :: result()
  def list(client, host_id, opts \\ []) do
    params = opts |> Keyword.take([:page, :per_page]) |> Enum.reject(fn {_, v} -> is_nil(v) end)
    Client.get(client, "/opencomputers/hosts/#{host_id}/exec", params: params)
  end

  @doc "Get a specific job by ID."
  @spec get(Client.t(), String.t(), String.t()) :: result()
  def get(client, host_id, job_id) do
    Client.get(client, "/opencomputers/hosts/#{host_id}/exec/#{job_id}")
  end

  @doc """
  Stream live output events from a running job (SSE).

  The callback receives `%{type: type, data: data}` maps. Blocks until done.
  """
  @spec stream(Client.t(), String.t(), String.t(), function()) :: :ok | {:error, Miosa.Error.t()}
  def stream(client, host_id, job_id, callback) when is_function(callback, 1) do
    Client.stream_sse(client, "/opencomputers/hosts/#{host_id}/exec/#{job_id}/stream", callback)
  end

  @doc "Cancel a running job."
  @spec cancel(Client.t(), String.t(), String.t()) :: result()
  def cancel(client, host_id, job_id) do
    Client.delete(client, "/opencomputers/hosts/#{host_id}/exec/#{job_id}")
  end
end

defmodule Miosa.OpenComputers.Fs do
  @moduledoc """
  Remote file system operations on registered hosts.
  """

  alias Miosa.Client

  @type result :: {:ok, map()} | {:error, Miosa.Error.t()}

  @doc "List directory entries at `remote_path`."
  @spec list(Client.t(), String.t(), String.t()) :: result()
  def list(client, host_id, remote_path) do
    Client.get(client, "/opencomputers/hosts/#{host_id}/fs/list", params: [path: remote_path])
  end

  @doc "Stat a path (size, mode, is_dir, symlink, etc.)."
  @spec stat(Client.t(), String.t(), String.t()) :: result()
  def stat(client, host_id, remote_path) do
    Client.get(client, "/opencomputers/hosts/#{host_id}/fs/stat", params: [path: remote_path])
  end

  @doc "Download a file as binary."
  @spec download(Client.t(), String.t(), String.t()) ::
          {:ok, binary()} | {:error, Miosa.Error.t()}
  def download(client, host_id, remote_path) do
    encoded = URI.encode_www_form(remote_path)
    Client.get_binary(client, "/opencomputers/hosts/#{host_id}/fs/download?path=#{encoded}")
  end

  @doc "Upload `content` (binary) to `remote_path` on the host."
  @spec upload(Client.t(), String.t(), String.t(), binary(), String.t()) :: result()
  def upload(client, host_id, remote_path, content, filename \\ "file") do
    encoded = URI.encode_www_form(remote_path)

    Client.post_multipart(
      client,
      "/opencomputers/hosts/#{host_id}/fs/upload?path=#{encoded}",
      [{:file, content, [filename: filename]}]
    )
  end

  @doc "Delete a file or directory on the host."
  @spec delete(Client.t(), String.t(), String.t()) :: result()
  def delete(client, host_id, remote_path) do
    encoded = URI.encode_www_form(remote_path)
    Client.delete(client, "/opencomputers/hosts/#{host_id}/fs/delete?path=#{encoded}")
  end

  @doc "Create a directory (and all parents) on the host."
  @spec mkdir(Client.t(), String.t(), String.t()) :: result()
  def mkdir(client, host_id, remote_path) do
    Client.post(client, "/opencomputers/hosts/#{host_id}/fs/mkdir", %{path: remote_path})
  end
end

defmodule Miosa.OpenComputers.Terminal do
  @moduledoc """
  Issue WebSocket tickets for terminal sessions on registered hosts.
  """

  alias Miosa.Client

  @type result :: {:ok, map()} | {:error, Miosa.Error.t()}

  @doc """
  Issue a short-lived WebSocket ticket for a terminal session.

  Connect immediately to `ws_url` using the returned `ticket`. The ticket
  expires in a few seconds.
  """
  @spec ticket(Client.t(), String.t()) :: result()
  def ticket(client, host_id) do
    Client.post(client, "/opencomputers/hosts/#{host_id}/terminal/ticket", nil)
  end
end

defmodule Miosa.OpenComputers.DesktopVnc do
  @moduledoc """
  Issue WebSocket tickets for desktop (VNC/KasmVNC) sessions on registered hosts.
  """

  alias Miosa.Client

  @type result :: {:ok, map()} | {:error, Miosa.Error.t()}

  @doc """
  Issue a short-lived WebSocket ticket for a desktop session.

  Connect immediately to `ws_url` using the returned `ticket`.
  """
  @spec ticket(Client.t(), String.t()) :: result()
  def ticket(client, host_id) do
    Client.post(client, "/opencomputers/hosts/#{host_id}/desktop/ticket", nil)
  end
end

defmodule Miosa.OpenComputers.Tunnels do
  @moduledoc """
  HTTP tunnel management for registered hosts.

  Tunnels expose a local port on the host over a MIOSA-managed public URL.
  """

  alias Miosa.Client

  @type result :: {:ok, map()} | {:error, Miosa.Error.t()}

  @doc "List all tunnels for a host."
  @spec list(Client.t(), String.t()) :: result()
  def list(client, host_id) do
    Client.get(client, "/opencomputers/hosts/#{host_id}/tunnels")
  end

  @doc """
  Create an HTTP tunnel exposing a local port on the host.

  `attrs` must include `:target_port`. Optional: `:auth_mode`, `:slug`.
  """
  @spec create(Client.t(), String.t(), map()) :: result()
  def create(client, host_id, attrs) when is_map(attrs) do
    Client.post(client, "/opencomputers/hosts/#{host_id}/tunnels", attrs)
  end

  @doc "Get a specific tunnel."
  @spec get(Client.t(), String.t(), String.t()) :: result()
  def get(client, host_id, tunnel_id) do
    Client.get(client, "/opencomputers/hosts/#{host_id}/tunnels/#{tunnel_id}")
  end

  @doc "Update a tunnel (port, auth mode, enabled flag)."
  @spec update(Client.t(), String.t(), String.t(), map()) :: result()
  def update(client, host_id, tunnel_id, attrs) when is_map(attrs) do
    Client.patch(client, "/opencomputers/hosts/#{host_id}/tunnels/#{tunnel_id}", attrs)
  end

  @doc "Delete a tunnel."
  @spec delete(Client.t(), String.t(), String.t()) :: result()
  def delete(client, host_id, tunnel_id) do
    Client.delete(client, "/opencomputers/hosts/#{host_id}/tunnels/#{tunnel_id}")
  end
end

defmodule Miosa.OpenComputers.Agents do
  @moduledoc """
  AI agent dispatch for registered hosts.

  Dispatch an AI agent to autonomously complete a task on your host. The agent
  can run commands, edit files, browse the web, and more.
  """

  alias Miosa.Client

  @type result :: {:ok, map()} | {:error, Miosa.Error.t()}

  @doc """
  Dispatch an AI agent to run a task on the host.

  `attrs` must include `:task`. Optional: `:model_id`, `:max_turns`, `:context`.
  """
  @spec dispatch(Client.t(), String.t(), map()) :: result()
  def dispatch(client, host_id, attrs) when is_map(attrs) do
    Client.post(client, "/opencomputers/hosts/#{host_id}/agent/dispatch", attrs)
  end

  @doc "List agent sessions for a host."
  @spec list(Client.t(), String.t()) :: result()
  def list(client, host_id) do
    Client.get(client, "/opencomputers/hosts/#{host_id}/agent/sessions")
  end

  @doc "Get a specific agent session."
  @spec get(Client.t(), String.t(), String.t()) :: result()
  def get(client, host_id, session_id) do
    Client.get(client, "/opencomputers/hosts/#{host_id}/agent/sessions/#{session_id}")
  end

  @doc """
  Stream live events from an agent session (SSE).

  The callback receives `%{type: type, data: data}` maps. Blocks until done.
  """
  @spec events(Client.t(), String.t(), String.t(), function()) :: :ok | {:error, Miosa.Error.t()}
  def events(client, host_id, session_id, callback) when is_function(callback, 1) do
    Client.stream_sse(
      client,
      "/opencomputers/hosts/#{host_id}/agent/sessions/#{session_id}/stream",
      callback
    )
  end

  @doc "Cancel a running agent session."
  @spec cancel(Client.t(), String.t(), String.t()) :: result()
  def cancel(client, host_id, session_id) do
    Client.delete(client, "/opencomputers/hosts/#{host_id}/agent/sessions/#{session_id}")
  end
end

defmodule Miosa.OpenComputers.Clusters do
  @moduledoc """
  Inference cluster management.

  A cluster groups multiple registered hosts to serve an LLM model via an
  OpenAI-compatible endpoint at `/inference/{slug}/v1/chat/completions`.
  """

  alias Miosa.Client

  @type result :: {:ok, map()} | {:error, Miosa.Error.t()}

  @doc "List inference clusters."
  @spec list(Client.t()) :: result()
  def list(client), do: Client.get(client, "/opencomputers/clusters")

  @doc """
  Create an inference cluster.

  `attrs` must include `:name`, `:model`, `:host_ids`.
  """
  @spec create(Client.t(), map()) :: result()
  def create(client, attrs) when is_map(attrs) do
    Client.post(client, "/opencomputers/clusters", attrs)
  end

  @doc "Get a specific cluster."
  @spec get(Client.t(), String.t()) :: result()
  def get(client, cluster_id), do: Client.get(client, "/opencomputers/clusters/#{cluster_id}")

  @doc "Start a stopped cluster."
  @spec start(Client.t(), String.t()) :: result()
  def start(client, cluster_id) do
    Client.post(client, "/opencomputers/clusters/#{cluster_id}/start", nil)
  end

  @doc "Stop a running cluster."
  @spec stop(Client.t(), String.t()) :: result()
  def stop(client, cluster_id) do
    Client.post(client, "/opencomputers/clusters/#{cluster_id}/stop", nil)
  end

  @doc "Delete a cluster."
  @spec delete(Client.t(), String.t()) :: result()
  def delete(client, cluster_id),
    do: Client.delete(client, "/opencomputers/clusters/#{cluster_id}")
end

defmodule Miosa.OpenComputers.Secrets do
  @moduledoc """
  Encrypted secret management for OpenComputers.

  Secrets can be scoped to the whole tenant or to a specific host. The secret
  value is encrypted at rest and injected as environment variables on the host.
  """

  alias Miosa.Client

  @type result :: {:ok, map()} | {:error, Miosa.Error.t()}

  # ── Tenant-scoped secrets ─────────────────────────────────────────────────

  @doc "List tenant-scoped secrets."
  @spec list(Client.t()) :: result()
  def list(client), do: Client.get(client, "/opencomputers/secrets")

  @doc """
  Create a tenant-scoped secret.

  `attrs` must include `:name` and `:value`. Optional: `:description`.
  """
  @spec create(Client.t(), map()) :: result()
  def create(client, attrs) when is_map(attrs) do
    Client.post(client, "/opencomputers/secrets", attrs)
  end

  @doc "Update a tenant-scoped secret."
  @spec update(Client.t(), String.t(), map()) :: result()
  def update(client, secret_id, attrs) when is_map(attrs) do
    Client.patch(client, "/opencomputers/secrets/#{secret_id}", attrs)
  end

  @doc "Delete a tenant-scoped secret."
  @spec delete(Client.t(), String.t()) :: result()
  def delete(client, secret_id), do: Client.delete(client, "/opencomputers/secrets/#{secret_id}")

  # ── Host-scoped secrets ───────────────────────────────────────────────────

  @doc "List secrets scoped to a specific host."
  @spec list_for_host(Client.t(), String.t()) :: result()
  def list_for_host(client, host_id) do
    Client.get(client, "/opencomputers/hosts/#{host_id}/secrets")
  end

  @doc "Create a secret scoped to a specific host."
  @spec create_for_host(Client.t(), String.t(), map()) :: result()
  def create_for_host(client, host_id, attrs) when is_map(attrs) do
    Client.post(client, "/opencomputers/hosts/#{host_id}/secrets", attrs)
  end

  @doc "Delete a host-scoped secret."
  @spec delete_for_host(Client.t(), String.t(), String.t()) :: result()
  def delete_for_host(client, host_id, secret_id) do
    Client.delete(client, "/opencomputers/hosts/#{host_id}/secrets/#{secret_id}")
  end
end
