# `Miosa.Mcp`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/mcp.ex#L1)

Model Context Protocol — JSON-RPC dispatch and streaming SSE channel.

Clients (Claude Code, Cursor, Gemini CLI, GitHub Copilot) point at
`/api/v1/mcp` with a `msk_*` Bearer token and discover the MIOSA
tool-belt via this endpoint.

## Example

    client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

    {:ok, result} = Miosa.Mcp.dispatch(client, %{
      method: "tools/call",
      params: %{name: "computer_screenshot", arguments: %{computer_id: "abc"}}
    })

# `close`

```elixir
@spec close(Miosa.Client.t()) :: Miosa.Client.result(map())
```

Close (terminate) the MCP session.

# `dispatch`

```elixir
@spec dispatch(Miosa.Client.t(), map()) :: Miosa.Client.result(map())
```

Send a JSON-RPC request to the MCP endpoint.

`body` map may contain `:method`, `:params`, and any additional JSON-RPC
fields (`id`, `jsonrpc`, etc.).

# `listen`

```elixir
@spec listen(Miosa.Client.t()) :: Miosa.Client.result(map())
```

Open the MCP listen channel (GET).

For true SSE streaming use `Miosa.Client.stream_sse/4` directly.
This function returns the initial response body for one-shot callers.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
