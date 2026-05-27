# `Miosa.Services`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/services.ex#L1)

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

# `create_params`

```elixir
@type create_params() :: %{
  :name =&gt; String.t(),
  :command =&gt; String.t(),
  optional(:working_dir) =&gt; String.t(),
  optional(:env) =&gt; map(),
  optional(:auto_restart) =&gt; boolean()
}
```

# `create`

```elixir
@spec create(Miosa.Client.t(), String.t(), create_params()) ::
  Miosa.Client.result(Miosa.Types.Service.t())
```

Creates a new service definition inside a computer.

## Params

  * `:name` — Required. Unique name for the service within this computer.
  * `:command` — Required. Shell command to run.
  * `:working_dir` — Working directory. Defaults to `"/home/user"`.
  * `:env` — Map of additional environment variables.
  * `:auto_restart` — Restart on crash. Defaults to `false`.

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t(), String.t()) ::
  :ok | {:error, Miosa.Error.t()}
```

Deletes a service definition.

The service must be stopped before deletion.

# `get`

```elixir
@spec get(Miosa.Client.t(), String.t(), String.t()) ::
  Miosa.Client.result(Miosa.Types.Service.t())
```

Fetches a single service by ID.

# `list`

```elixir
@spec list(Miosa.Client.t(), String.t()) ::
  Miosa.Client.result([Miosa.Types.Service.t()])
```

Lists all services for a computer.

# `logs`

```elixir
@spec logs(Miosa.Client.t(), String.t(), String.t(), keyword()) :: Enumerable.t()
```

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

# `restart`

```elixir
@spec restart(Miosa.Client.t(), String.t(), String.t()) ::
  :ok | {:error, Miosa.Error.t()}
```

Restarts a service (stop + start).

# `start`

```elixir
@spec start(Miosa.Client.t(), String.t(), String.t()) ::
  :ok | {:error, Miosa.Error.t()}
```

Starts a service.

# `stop`

```elixir
@spec stop(Miosa.Client.t(), String.t(), String.t()) ::
  :ok | {:error, Miosa.Error.t()}
```

Stops a running service.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
