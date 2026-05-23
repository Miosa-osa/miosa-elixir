defmodule Miosa.Sandbox.Events do
  @moduledoc """
  SSE event streams for a sandbox.

    * `GET /sandboxes/:id/events`             — stream/3
    * `GET /sandboxes/:id/files/watch?path=…` — watch_dir/4
  """

  alias Miosa.Client

  @doc """
  Stream live sandbox events via SSE (GET `/sandboxes/:sandbox_id/events`).

  `callback` is called for each event map with keys `type` and `data`.
  Returns `:ok` when the stream closes or `{:error, reason}` on failure.
  """
  @spec stream(Client.t(), String.t(), function()) :: :ok | {:error, Miosa.Error.t()}
  def stream(%Client{} = client, sandbox_id, callback)
      when is_binary(sandbox_id) and is_function(callback, 1) do
    Client.stream_sse(client, "/sandboxes/#{sandbox_id}/events", callback)
  end

  @doc """
  Watch a directory for filesystem changes via SSE
  (GET `/sandboxes/:sandbox_id/files/watch?path=…`).

  `callback` is called for each event map with keys `type` and `data`.
  Returns `:ok` when the stream closes or `{:error, reason}` on failure.

  ## Options

    * `:recursive` — When `true`, watch the directory tree recursively. Defaults to `false`.
  """
  @spec watch_dir(Client.t(), String.t(), String.t(), function(), keyword()) ::
          :ok | {:error, Miosa.Error.t()}
  def watch_dir(%Client{} = client, sandbox_id, path, callback, opts \\ [])
      when is_binary(sandbox_id) and is_binary(path) and is_function(callback, 1) do
    params =
      [{"path", path}]
      |> maybe_put_param(:recursive, Keyword.get(opts, :recursive))

    query = URI.encode_query(params)

    Client.stream_sse(client, "/sandboxes/#{sandbox_id}/files/watch?#{query}", callback)
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp maybe_put_param(params, _key, nil), do: params
  defp maybe_put_param(params, key, value), do: params ++ [{to_string(key), to_string(value)}]
end
