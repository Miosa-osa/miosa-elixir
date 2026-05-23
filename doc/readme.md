# miosa (Elixir)

> Official Elixir SDK for MIOSA — the AI cloud platform for sandboxes, computers, deployments, and managed data.

[![Hex version](https://img.shields.io/hexpm/v/miosa.svg)](https://hex.pm/packages/miosa)
[![Hex downloads](https://img.shields.io/hexpm/dt/miosa.svg)](https://hex.pm/packages/miosa)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docs](https://img.shields.io/badge/docs-hexdocs.pm%2Fmiosa-blue)](https://hexdocs.pm/miosa)

Elixir 1.15+. HTTP transport via `Req`, JSON via `Jason`.

## Install

```elixir
def deps do
  [
    {:miosa, "~> 1.0"}
  ]
end
```

Then run `mix deps.get`.

## Quickstart

```elixir
client = Miosa.client("msk_live_...")

{:ok, computer} = Miosa.Computers.create(client, %{
  name: "my-build",
  template_type: "miosa-sandbox",
  size: "small"
})

{:ok, result} = Miosa.Exec.bash(client, computer.id, "echo 'hello from miosa'")
IO.puts(result.output)  # hello from miosa

{:ok, _} = Miosa.Files.write_file(client, computer.id, "/workspace/app.exs", ~s(IO.puts("hi")))
{:ok, text} = Miosa.Files.read_file(client, computer.id, "/workspace/app.exs")

:ok = Miosa.Computers.delete(client, computer.id)
```

## What's included

| Module | Description |
|---|---|
| **Computers** | |
| `Miosa.Computers` | Create, list, get, update, delete computers |
| `Miosa.Computer` | Bound handle — start, stop, restart, clone, resize, wait |
| `Miosa.Computer.Agent` | CUA sessions — run, list, get, cancel AI agent sessions |
| `Miosa.Computer.Env` | Per-computer environment variables |
| `Miosa.Computer.Logs` | Computer log retrieval + SSE streaming |
| `Miosa.Computer.Metrics` | CPU/memory metrics |
| `Miosa.Computer.Ports` | Port mapping CRUD |
| `Miosa.Computer.Terminal` | PTY session create + resize |
| `Miosa.Computer.Volumes` | Attach/detach volumes to computers |
| `Miosa.Computer.AutoStop` | Auto-stop timer get/update |
| `Miosa.Computer.Inbox` | Computer inbox get/update |
| `Miosa.Computer.Osa` | OSA agent task submit/cancel/configure |
| **Desktop** | |
| `Miosa.Desktop` | Screenshot, click, double_click, right_click, type, key, hotkey, scroll, drag, move, launch, windows, cursor, focus_window |
| **Exec & Files** | |
| `Miosa.Exec` | `bash/4`, `python/4`, `spawn/4` execution inside VMs |
| `Miosa.Exec.Command` | WebSocket PTY — send_stdin, resize, await |
| `Miosa.Files` | Upload, download, write, read, list, stat, mkdir, rename, copy, chmod, delete, export |
| **Sandboxes** | |
| `Miosa.Sandboxes` | Create, list, get, delete sandboxes + wait_until_ready |
| `Miosa.Sandbox.Processes` | Background process start/list/kill/send_stdin |
| `Miosa.Sandbox.Events` | SSE event streaming + file watch |
| `Miosa.Sandbox.Previews` | Preview URL create/list/share/revoke |
| `Miosa.Sandbox.Terminal` | Sandbox PTY session create/delete |
| `Miosa.Sandbox.Env` | Sandbox environment variables |
| `Miosa.Sandbox.Tags` | Sandbox tag management |
| `Miosa.SandboxTemplates` | Template CRUD + builds |
| **Deployments** | |
| `Miosa.Deployments` | Create, list, publish, rollback, versions, releases, builds, env, domains, runtime instances |
| **Data** | |
| `Miosa.Databases` | Create, list, get, delete, start/stop/restart, credentials, logs |
| `Miosa.Storage` | Buckets CRUD + objects put/get/delete/list + presign |
| `Miosa.Volumes` | Volume CRUD |
| **Platform** | |
| `Miosa.Functions` | Edge functions CRUD + invoke |
| `Miosa.Webhooks` | Webhook CRUD + test + deliveries |
| `Miosa.CronJobs` | Cron job CRUD + pause/resume/run_now + executions |
| `Miosa.ApiKeys` | API key CRUD |
| `Miosa.Workspaces` | Workspace CRUD + list_computers |
| `Miosa.CustomDomains` | Custom domain register/verify/delete |
| `Miosa.NetworkPolicy` | Network policy get/set/reset |
| `Miosa.Services` | Service CRUD + start/stop/restart/logs |
| `Miosa.Checkpoints` | Snapshot create/list/restore/delete |
| `Miosa.Events` | SSE event streaming per computer |
| `Miosa.Settings` | Platform settings + branding |
| `Miosa.Credits` | Credit balance + transactions |
| `Miosa.Completions` | Chat/text completions + SSE streaming |
| `Miosa.Regions` | Available regions |
| **BYOC & Admin** | |
| `Miosa.OpenComputers` | BYOC host management (hosts, jobs, tunnels, agents, clusters, secrets) |
| `Miosa.Admin` | Admin-scoped operations (dashboard, users, tenants, credits, plans) |

## Exec

```elixir
{:ok, result} = Miosa.Exec.bash(client, computer.id, "ls -la /workspace",
  timeout: 10_000,
  working_dir: "/workspace",
  env: %{"DEBUG" => "1"}
)
IO.puts(result.stdout)
IO.puts("exit: #{result.exit_code}")

{:ok, py} = Miosa.Exec.python(client, computer.id, """
  import json
  print(json.dumps({"status": "ok"}))
""")
IO.puts(py.output)
```

## File operations

```elixir
# Write / read
{:ok, _} = Miosa.Files.write_file(client, id, "/workspace/app.py", "print('hi')")
{:ok, text} = Miosa.Files.read_file(client, id, "/workspace/app.py")

# Upload binary
{:ok, _} = Miosa.Files.upload(client, id, "./local.txt", "/workspace/remote.txt")

# List / stat / mkdir / rename / delete
{:ok, entries} = Miosa.Files.list(client, id, "/workspace")
{:ok, stat}    = Miosa.Files.stat(client, id, "/workspace/app.py")
{:ok, _}       = Miosa.Files.mkdir(client, id, "/workspace/output")
{:ok, _}       = Miosa.Files.rename(client, id, "/workspace/old.py", "/workspace/new.py")
:ok            = Miosa.Files.delete(client, id, "/workspace/old.py")
```

## Desktop control

```elixir
{:ok, png} = Miosa.Desktop.screenshot(client, computer.id)
File.write!("screen.png", png)

:ok = Miosa.Desktop.click(client, computer.id, 640, 400)
:ok = Miosa.Desktop.double_click(client, computer.id, 640, 400)
:ok = Miosa.Desktop.right_click(client, computer.id, 640, 400)
:ok = Miosa.Desktop.type(client, computer.id, "hello world")
:ok = Miosa.Desktop.key(client, computer.id, "Return")
:ok = Miosa.Desktop.key(client, computer.id, "ctrl+c")
:ok = Miosa.Desktop.scroll(client, computer.id, 640, 400, "down", 3)
:ok = Miosa.Desktop.drag(client, computer.id, 100, 100, 400, 400)

{:ok, windows} = Miosa.Desktop.windows(client, computer.id)
{:ok, cursor}  = Miosa.Desktop.cursor(client, computer.id)
:ok            = Miosa.Desktop.launch(client, computer.id, "firefox")
```

## SSE event streaming

```elixir
:ok = Miosa.Events.stream(client, computer.id, fn event ->
  IO.inspect({event.type, event.data})
end)
```

## OTP / Supervisor integration

```elixir
children = [
  {Miosa.Client, api_key: System.fetch_env!("MIOSA_API_KEY")}
]

Supervisor.start_link(children, strategy: :one_for_one)
```

## Phoenix / LiveView integration

```elixir
defmodule MyAppWeb.SandboxLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))
    {:ok, assign(socket, client: client, output: nil)}
  end

  def handle_event("run", %{"cmd" => cmd}, socket) do
    {:ok, result} = Miosa.Exec.bash(
      socket.assigns.client,
      socket.assigns.computer_id,
      cmd
    )
    {:noreply, assign(socket, output: result.output)}
  end
end
```

## White-label / multi-tenant

```elixir
{:ok, computer} = Miosa.Computers.create(client, %{
  name: "customer-build",
  template_type: "miosa-sandbox",
  metadata: %{
    "external_workspace_id" => "acme-corp",
    "external_user_id"      => "user-99"
  }
})
```

## Error handling

All functions return `{:ok, result}` or `{:error, %Miosa.Error{}}`:

```elixir
case Miosa.Computers.get(client, "cmp_doesnt_exist") do
  {:ok, computer} ->
    computer

  {:error, %Miosa.Error{status: 404}} ->
    IO.puts("not found")

  {:error, %Miosa.Error{status: 429, message: msg}} ->
    IO.puts("rate limited: #{msg}")

  {:error, %Miosa.Error{message: msg}} ->
    IO.puts("error: #{msg}")
end
```

`Miosa.Error` fields: `:message`, `:status`, `:code`, `:body`.

## Configuration

```elixir
client = Miosa.client("msk_live_...",
  base_url:        "https://api.miosa.ai/api/v1",
  timeout:         30_000,
  receive_timeout: 60_000,
  retry:           false
)
```

| Option | Default |
|---|---|
| `:api_key` | required — pass explicitly; env var not auto-read |
| `:base_url` | `https://api.miosa.ai/api/v1` |
| `:timeout` | `30_000` ms |
| `:receive_timeout` | `60_000` ms |
| `:retry` | `false` |

## Links

- [HexDocs reference](https://hexdocs.pm/miosa)
- [Full documentation](https://miosa.ai/docs/sdks/elixir)
- [Quickstart](https://miosa.ai/docs/quickstart)
- [GitHub](https://github.com/Miosa-osa/miosa-elixir)
- [Contact](mailto:platform@miosa.ai)

## License

MIT
