# `Miosa.Sandboxes`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/sandboxes.ex#L1)

Sandboxes — a thin helper over `Miosa.Computers` that defaults
`template_type` to `"miosa-sandbox"` (ephemeral code-exec rootfs, no
desktop).

Mirrors the one-resource product model used by E2B and Daytona: the
computer is the single resource type, and `template_type` selects its
flavour. A sandbox is just a computer with the lightweight template;
every other module (`Miosa.Computer`, `Miosa.Exec`, `Miosa.Files`,
`Miosa.Desktop`) works identically.

## Example

    client = Miosa.client("msk_u_...")

    {:ok, sandbox} = Miosa.Sandboxes.create(client, %{name: "quick-exec"})
    :ok = Miosa.Computer.start(client, sandbox.id)
    {:ok, %{output: out}} = Miosa.Exec.run(client, sandbox.id, command: "echo hi")
    :ok = Miosa.Computer.destroy(client, sandbox.id)

# `create`

```elixir
@spec create(Miosa.Client.t(), map()) :: Miosa.Client.result(Miosa.Types.Computer.t())
```

Create a sandbox — a computer provisioned with the `miosa-sandbox` template.

Accepts the same attributes as `Miosa.Computers.create/2`; the
`template_type` key defaults to `"miosa-sandbox"` when omitted.

## White-label attribution

Pass `:external_workspace_id`, `:external_user_id`, `:external_project_id`
to tag the sandbox with your platform's customer/user/project IDs. These
fields never authorize anything — tenancy is always derived server-side
from the API key — but they let your list/usage APIs group by attribution.

    {:ok, sandbox} = Miosa.Sandboxes.create(client, %{
      name: "smile-dental",
      external_workspace_id: "dental-office-123",
      external_user_id: "dr-smith-456",
      external_project_id: "landing-page-789"
    })

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Destroy a sandbox. Alias for `Miosa.Computers.delete/2`.

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t()) ::
  Miosa.Client.result(Miosa.Types.Computer.t())
```

Get a sandbox by ID. Alias for `Miosa.Computers.get/2`.

# `list`

```elixir
@spec list(Miosa.Client.t()) :: Miosa.Client.result([Miosa.Types.Computer.t()])
```

List sandboxes — filtered to computers whose `template_type` is
`"miosa-sandbox"`.

# `readiness`

```elixir
@spec readiness(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Return the readiness-probe state for a sandbox
(GET `/sandboxes/:sandbox_id/readiness`).

Useful to poll after creation before issuing exec commands.

# `template`

```elixir
@spec template() :: String.t()
```

Template slug used for the lightweight code-exec sandbox rootfs.

# `wait_until_ready`

```elixir
@spec wait_until_ready(Miosa.Client.t(), String.t(), keyword()) ::
  {:ok, boolean()} | {:error, Miosa.Error.t()}
```

Block until the sandbox reports ready, or `timeout` seconds elapse.

## Options

  * `:timeout` — seconds to wait. Defaults to `30`.
  * `:stream`  — when `true` (the default) the SDK first attempts the
    server-side SSE endpoint `GET /sandboxes/:id/readiness/stream` which
    pushes `event: ready` as soon as the sandbox boots (and immediately if
    it is already ready). When `false` the SDK only polls.

Returns `{:ok, true}` once ready, `{:ok, false}` on the server-emitted
`event: timeout` frame or when the local timeout elapses before ready.

If the SSE endpoint returns 404 (server pre-dates the streaming endpoint)
this transparently falls back to polling `readiness/2` every 10 ms.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
