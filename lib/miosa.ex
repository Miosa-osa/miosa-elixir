defmodule Miosa do
  @moduledoc """
  Official Elixir SDK for the MIOSA API.

  MIOSA provides cloud computers (Linux VMs with a full desktop) accessible via
  API. This SDK covers computer management, desktop control, file operations,
  and command execution. The desktop and exec primitives let your own AI
  agent (Claude, GPT, your own model, etc.) drive a MIOSA computer.

  ## Installation

  Add to your `mix.exs`:

      defp deps do
        [
          {:miosa, "~> 0.1.0"}
        ]
      end

  ## Quick Start

      # Build a client
      client = Miosa.client("msk_u_your_api_key")

      # Create and start a computer
      {:ok, computer} = Miosa.Computers.create(client, %{name: "my-workspace"})
      :ok = Miosa.Computer.start(client, computer.id)
      {:ok, computer} = Miosa.Computer.wait_until_running(client, computer.id)

      # Control the desktop
      {:ok, png} = Miosa.Desktop.screenshot(client, computer.id)
      :ok = Miosa.Desktop.click(client, computer.id, 500, 300)
      :ok = Miosa.Desktop.type(client, computer.id, "Hello, world!")
      :ok = Miosa.Desktop.key(client, computer.id, "Return")

      # Run commands
      {:ok, result} = Miosa.Exec.bash(client, computer.id, "echo hello")
      IO.puts(result.output)

      # Upload and download files
      :ok = Miosa.Files.upload(client, computer.id, "./local.txt", "/home/user/file.txt")
      {:ok, content} = Miosa.Files.download(client, computer.id, "/home/user/file.txt")

      # Drive the desktop yourself with your own AI agent — the SDK gives
      # you the primitives (screenshot/click/type/key), you provide the loop:
      {:ok, png} = Miosa.Desktop.screenshot(client, computer.id)
      # ... pass `png` to your LLM, get back actions, replay via Miosa.Desktop ...

      # Clean up
      :ok = Miosa.Computer.stop(client, computer.id)
      :ok = Miosa.Computer.destroy(client, computer.id)

  ## API Key

  Get your API key from the MIOSA dashboard at https://app.miosa.ai/settings/api.
  Keys have the format `msk_u_...` (user), `msk_a_...` (admin), or `msk_p_...` (platform).

  Set via environment variable for safety:

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

  ## Modules

    * `Miosa.Computers` — Create, list, get, delete computers
    * `Miosa.Computer` — Start, stop, restart, destroy a computer; wait for state transitions
    * `Miosa.Sandboxes` — Thin helper that creates lightweight code-exec computers (`miosa-sandbox` template)
    * `Miosa.Deployments` — Publish from a sandbox to a stable production URL; versions, rollback, custom domains
    * `Miosa.Desktop` — Screenshot, click, type, key, scroll, drag, windows, cursor
    * `Miosa.Exec` — Run bash and Python inside a computer
    * `Miosa.Files` — Upload, download, list, export, delete, write files
    * `Miosa.Credits` — Query credit balance, transactions, usage
    * `Miosa.Admin` — Admin surface (`/admin/*`): users, tenants, credits, keys, Optimal model management (requires `msk_a_` / `msk_p_` key or admin JWT)
    * `Miosa.Databases` — Managed Postgres databases: CRUD, start/stop/restart, credentials, logs
    * `Miosa.Storage` — S3-compatible object storage: buckets, objects, presigned URLs
    * `Miosa.Volumes` — Persistent block storage volumes: CRUD
    * `Miosa.FlatCustomDomains` — Tenant-scoped custom domains across all computers/deployments
    * `Miosa.Functions` — Edge functions: CRUD + synchronous invocation
    * `Miosa.CronJobs` — Scheduled jobs: CRUD, pause/resume, run-now, execution history
    * `Miosa.HealthChecks` — Uptime monitors: CRUD
    * `Miosa.Webhooks` — Outgoing webhooks: CRUD, test delivery, delivery history
    * `Miosa.SandboxTemplates` — Sandbox base images: CRUD, build-spec schema, validate, builds
    * `Miosa.ApiKeys` — Programmatic API key management: list, create, revoke
    * `Miosa.Tenant` — Current tenant plan limits and live usage counters
    * `Miosa.Regions` — Datacenter regions, compute sizes, pricing, community templates
    * `Miosa.Settings` — Tenant workspace config, branding, BYOK provider keys
    * `Miosa.Dashboard` — Aggregated platform overview and health status
    * `Miosa.Analytics` — Admin-scoped overview and timeseries metrics
    * `Miosa.AuditLog` — Admin-scoped event stream
    * `Miosa.Usage` — Current period summary, per-session metering, report queries
    * `Miosa.Channels` — Notification channels (Slack, Discord, email): CRUD + enable/disable
    * `Miosa.Integrations` — OAuth account-level integrations: GitHub, Slack, Linear, Discord
    * `Miosa.ProjectIntegrations` — Per-project provider keys injected as env vars into VMs
    * `Miosa.ProjectAuth` — Built-in auth for generated apps inside sandboxes/deployments
    * `Miosa.ExternalKeys` — BYOK encrypted per-user provider keys (Anthropic, OpenAI, etc.)
    * `Miosa.Mcp` — Model Context Protocol JSON-RPC dispatch and SSE channel
    * `Miosa.Models` — List available LLM models via the intelligence gateway
    * `Miosa.Completions` — OpenAI-compatible text and chat completions (streaming supported)
    * `Miosa.Embeddings` — OpenAI-compatible embedding vectors
    * `Miosa.ProviderDefaults` — Admin: fleet-wide LLM provider routing defaults + per-tenant overrides
    * `Miosa.Benchmarks` — Admin: trigger and inspect platform benchmark runs
    * `Miosa.CommandCenter` — Read-only views of the Optimal AI agent fleet + SSE event stream
    * `Miosa.Community` — Community template and agent catalog with install + rate actions
    * `Miosa.Email` — Admin email surface (sub-modules: `Miosa.Email.Campaigns`, `Miosa.Email.Templates`, `Miosa.Email.Inbox`)
    * `Miosa.BuilderSessions` — Durable cross-device Builder UI session metadata
    * `Miosa.SnapshotsStandalone` — Admin: fleet-wide snapshot index
    * `Miosa.Computer.Terminal` — PTY session create and resize
    * `Miosa.Computer.Osa` — In-VM OSA agent task dispatch, status, configure
    * `Miosa.Computer.AutoStop` — Idle-timeout config read/update
    * `Miosa.Computer.Inbox` — Per-computer inbound-email inbox config
    * `Miosa.Computer.Env` — Encrypted env-var CRUD (list, set, update, delete, bulk_set)
    * `Miosa.Computer.Logs` — Log snapshot + SSE stream
    * `Miosa.Computer.Metrics` — Time-series RAM/CPU/credit metrics
    * `Miosa.Computer.Ports` — Per-port visibility CRUD
    * `Miosa.Computer.Volumes` — Volume attachment management
    * `Miosa.Sandbox.Terminal` — Sandbox PTY session create and delete
    * `Miosa.Sandbox.Events` — Sandbox SSE event stream
    * `Miosa.Sandbox.Previews` — Preview URL CRUD + share/revoke token
    * `Miosa.Sandbox.Env` — Per-sandbox env-var reader
    * `Miosa.Sandbox.Tags` — Sandbox tag replacement
    * `Miosa.Secrets` — Tenant-wide encrypted secret vault + OAuth Connect flows
    * `Miosa.Network` — Tenant-wide egress allowlist and policy management
    * `Miosa.Audit` — Tenant-wide egress audit log query and long-poll Stream tail
    * `Miosa.OauthFlow` — OAuth Connect flow handle with `wait_for_completion/2`
    * `Miosa.Sandboxes.Secrets` — Sandbox-bound secrets (pre-scoped resource_id)
    * `Miosa.Sandboxes.Network` — Sandbox-bound network rules (pre-scoped resource_id)
    * `Miosa.Sandboxes.Audit` — Sandbox-bound audit tail with WebSocket upgrade
    * `Miosa.Client` — Low-level HTTP client (use directly for custom requests)
    * `Miosa.Types` — All response struct types
    * `Miosa.Error` — Exception type raised/returned on errors

  """

  @doc """
  Creates a new MIOSA API client.

  This is the entry point for all SDK operations. The returned client is a
  plain struct — it is stateless and safe to share across processes.

  ## Arguments

    * `api_key` — Your MIOSA API key. Must start with `"msk_"`.

  ## Options

    * `:base_url` — Override the API base URL. Defaults to `https://api.miosa.ai/api/v1`.
      Useful for local development with a self-hosted MIOSA instance.
    * `:timeout` — Connection timeout in milliseconds. Defaults to `30_000`.
    * `:receive_timeout` — Receive timeout for long-running requests. Defaults to `60_000`.
    * `:retry` — Enable automatic retry on transient failures. Defaults to `false`.

  ## Raises

    * `ArgumentError` — if the API key does not start with `"msk_"`.

  ## Example

      client = Miosa.client("msk_u_abcdef123")

      # Custom base URL for local dev
      client = Miosa.client("msk_u_abcdef123", base_url: "http://localhost:4000/api/v1")

  """
  @spec client(String.t(), keyword()) :: Miosa.Client.t()
  def client(api_key, opts \\ []) when is_binary(api_key) do
    Miosa.Client.new(api_key, opts)
  end
end
