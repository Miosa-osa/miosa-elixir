# `Miosa.Computer.Volumes`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/computer/volumes.ex#L1)

Per-computer volume attachment management.

  * `GET    /computers/:id/volumes`          — list/2
  * `POST   /computers/:id/volumes`          — attach/4
  * `DELETE /computers/:id/volumes/:aid`     — detach/3

# `attach`

```elixir
@spec attach(Miosa.Client.t(), String.t(), String.t(), String.t()) ::
  Miosa.Client.result(map())
```

Attach a volume at `mount_path` inside the VM
(POST `/computers/:computer_id/volumes`).

# `detach`

```elixir
@spec detach(Miosa.Client.t(), String.t(), String.t()) ::
  :ok | {:error, Miosa.Error.t()}
```

Detach a volume attachment by attachment ID
(DELETE `/computers/:computer_id/volumes/:attachment_id`).

# `list`

```elixir
@spec list(Miosa.Client.t(), String.t()) :: Miosa.Client.result(list())
```

List volume attachments for a computer
(GET `/computers/:computer_id/volumes`).

---

*Consult [api-reference.md](api-reference.md) for complete listing*
