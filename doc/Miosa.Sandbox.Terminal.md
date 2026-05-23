# `Miosa.Sandbox.Terminal`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/sandbox/terminal.ex#L1)

PTY session control for a sandbox.

  * `POST   /sandboxes/:id/terminal`                — create/2
  * `DELETE /sandboxes/:id/terminal/:session_id`    — delete/3

# `create`

```elixir
@spec create(Miosa.Client.t(), String.t(), map()) :: Miosa.Client.result(map())
```

Open a new PTY session (POST `/sandboxes/:sandbox_id/terminal`).

## Options map keys

  * `"cols"` — Terminal column width.
  * `"rows"` — Terminal row count.
  * `"shell"` — Shell binary path.
  * `"cwd"` — Working directory.
  * `"env"` — Environment variables map.

# `delete`

```elixir
@spec delete(Miosa.Client.t(), String.t(), String.t()) ::
  :ok | {:error, Miosa.Error.t()}
```

Delete a PTY session (DELETE `/sandboxes/:sandbox_id/terminal/:session_id`).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
