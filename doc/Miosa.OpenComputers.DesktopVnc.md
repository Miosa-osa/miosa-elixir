# `Miosa.OpenComputers.DesktopVnc`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.1/lib/miosa/open_computers.ex#L228)

Issue WebSocket tickets for desktop (VNC/KasmVNC) sessions on registered hosts.

# `result`

```elixir
@type result() :: {:ok, map()} | {:error, Miosa.Error.t()}
```

# `ticket`

```elixir
@spec ticket(Miosa.Client.t(), String.t()) :: result()
```

Issue a short-lived WebSocket ticket for a desktop session.

Connect immediately to `ws_url` using the returned `ticket`.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
