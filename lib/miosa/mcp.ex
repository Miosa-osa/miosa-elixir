defmodule Miosa.Mcp do
  @moduledoc """
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
  """

  alias Miosa.Client

  @doc """
  Send a JSON-RPC request to the MCP endpoint.

  `body` map may contain `:method`, `:params`, and any additional JSON-RPC
  fields (`id`, `jsonrpc`, etc.).
  """
  @spec dispatch(Client.t(), map()) :: Client.result(map())
  def dispatch(client, body \\ %{}) when is_map(body) do
    payload = strip_nil(body)
    Client.post(client, "/mcp", if(payload == %{}, do: nil, else: payload))
  end

  @doc """
  Open the MCP listen channel (GET).

  For true SSE streaming use `Miosa.Client.stream_sse/4` directly.
  This function returns the initial response body for one-shot callers.
  """
  @spec listen(Client.t()) :: Client.result(map())
  def listen(client) do
    Client.get(client, "/mcp")
  end

  @doc "Close (terminate) the MCP session."
  @spec close(Client.t()) :: Client.result(map())
  def close(client) do
    Client.delete(client, "/mcp")
  end

  # ── Helpers ───────────────────────────────────────────────────────────────────

  defp strip_nil(map) when is_map(map) do
    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end
end
