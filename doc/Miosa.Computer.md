# `Miosa.Computer`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/computer.ex#L1)

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

# `apps`

```elixir
@spec apps(Miosa.Client.t(), String.t()) :: Miosa.Client.result(list())
```

List installed applications on a computer (GET `/computers/:computer_id/apps`).

# `clone`

```elixir
@spec clone(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Clone a computer into a new computer (POST `/computers/:computer_id/clone`).

Optional `attrs` are merged into the clone creation payload.

# `destroy`

```elixir
@spec destroy(Miosa.Client.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
```

Destroys a computer permanently.

This is equivalent to `Miosa.Computers.delete/2` with `force: true`.
All data is lost. This action cannot be undone.

# `move`

```elixir
@spec move(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Move a computer to a different region or host
(POST `/computers/:computer_id/move`).

# `preview_url`

```elixir
@spec preview_url(Miosa.Client.t(), String.t(), pos_integer(), keyword()) ::
  String.t()
```

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

# `public_url`

```elixir
@spec public_url(Miosa.Client.t(), String.t(), keyword()) :: String.t()
```

Returns the public URL for the computer desktop stream.

This URL is the root access point for the computer's web interface
(VNC/KasmVNC). Requires the computer to be running and `:visibility`
set to `:public` or authenticated with an API key.

## Example

    url = Miosa.Computer.public_url(client, "comp_abc")
    # => "https://desktop.miosa.ai/comp_abc"

# `resize`

```elixir
@spec resize(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Resize a computer (PATCH `/computers/:computer_id/resize`).

Pass `cpu`, `memory_mb`, or any other size params.

# `restart`

```elixir
@spec restart(Miosa.Client.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
```

Restarts a running computer.

Equivalent to stop + start. The computer will be unavailable briefly
during the restart.

# `screenshot_region`

```elixir
@spec screenshot_region(
  Miosa.Client.t(),
  String.t(),
  integer(),
  integer(),
  integer(),
  integer()
) ::
  Miosa.Client.result(binary())
```

Take a screenshot of a sub-region
(GET `/computers/:computer_id/screenshot`).

Coordinates are in 0–1000 space (MIOSA canonical coordinate system).
Returns raw PNG binary.

# `start`

```elixir
@spec start(Miosa.Client.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
```

Starts a stopped computer.

Returns `:ok` once the start request is accepted. The computer transitions
through `:starting` → `:running`. Use `wait_until_running/3` to block until
ready.

# `stop`

```elixir
@spec stop(Miosa.Client.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
```

Stops a running computer (graceful shutdown).

The computer status transitions to `:stopping` → `:stopped`.

# `stream_token`

```elixir
@spec stream_token(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

Issue a short-lived stream token for a computer
(POST `/computers/:computer_id/stream-token`).

# `urls`

```elixir
@spec urls(Miosa.Client.t(), String.t()) :: Miosa.Client.result(map())
```

List the named public URLs for a computer (GET `/computers/:computer_id/urls`).

# `vnc_credentials`

```elixir
@spec vnc_credentials(Miosa.Client.t(), String.t()) ::
  :ok | {:error, Miosa.Error.t()} | Miosa.Client.result(map())
```

Fetch the VNC/KasmVNC credentials for a computer
(GET `/computers/:computer_id/vnc-credentials`).

# `wait_until_running`

```elixir
@spec wait_until_running(Miosa.Client.t(), String.t(), keyword()) ::
  {:ok, Miosa.Types.Computer.t()} | {:error, :timeout | Miosa.Error.t()}
```

Blocks until the computer reaches `:running` status or times out.

Polls `Miosa.Computers.get/2` every 2 seconds.

## Options

  * `:timeout` — Maximum wait time in milliseconds. Defaults to `300_000` (5 minutes).

## Returns

  * `{:ok, computer}` — when the computer is running.
  * `{:error, :timeout}` — if the computer did not reach `:running` within the timeout.
  * `{:error, reason}` — if the computer reaches `:error` status or an API error occurs.

# `wait_until_stopped`

```elixir
@spec wait_until_stopped(Miosa.Client.t(), String.t(), keyword()) ::
  {:ok, Miosa.Types.Computer.t()} | {:error, :timeout | Miosa.Error.t()}
```

Blocks until the computer reaches `:stopped` status or times out.

## Options

  * `:timeout` — Maximum wait time in milliseconds. Defaults to `300_000` (5 minutes).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
