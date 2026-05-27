defmodule Miosa.Sandbox.Files do
  @moduledoc """
  File-system operations on a sandbox.

  Wraps:
    * `GET  /sandboxes/:id/files/tree`       — tree/3
    * `POST /sandboxes/:id/files/write-many` — write_many/3
    * `GET  /sandboxes/:id/files/watch` (SSE) — watch/3
  """

  alias Miosa.Client

  @doc """
  Return a recursive file tree rooted at `path` up to `depth` levels.

  GET `/sandboxes/:sandbox_id/files/tree?path=<path>&depth=<depth>`

  Returns `{:ok, tree_node}` where the node has the shape:
  `%{"path" => _, "type" => "dir"|"file", "name" => _, "children" => [...]?}`.
  """
  @spec tree(Client.t(), String.t(), keyword()) :: Client.result(map())
  def tree(%Client{} = client, sandbox_id, opts \\ []) when is_binary(sandbox_id) do
    path = Keyword.get(opts, :path, "/workspace")
    depth = Keyword.get(opts, :depth, 3)
    qs = "path=#{URI.encode_www_form(path)}&depth=#{depth}"

    case Client.get(client, "/sandboxes/#{sandbox_id}/files/tree?#{qs}") do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, body} -> {:ok, body}
      err -> err
    end
  end

  @doc """
  Write multiple files in a single request.

  POST `/sandboxes/:sandbox_id/files/write-many`

  `files` is a list of `%{path: path, content: binary_or_string}`. Content
  is base64-encoded automatically.

  Returns `{:ok, %{"written" => [...], "failed" => [...]}}`.
  """
  @spec write_many(Client.t(), String.t(), list(map())) :: Client.result(map())
  def write_many(%Client{} = client, sandbox_id, files)
      when is_binary(sandbox_id) and is_list(files) do
    encoded =
      Enum.map(files, fn f ->
        content = Map.get(f, :content) || Map.get(f, "content") || ""

        content_b64 =
          if is_binary(content) do
            Base.encode64(content)
          else
            content
          end

        %{
          "path" => Map.get(f, :path) || Map.get(f, "path"),
          "content_base64" => content_b64
        }
      end)

    body = %{"files" => encoded}

    case Client.post(client, "/sandboxes/#{sandbox_id}/files/write-many", body) do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, body} -> {:ok, body}
      err -> err
    end
  end

  @doc """
  Stream file-system events from a sandbox as SSE.

  GET `/sandboxes/:sandbox_id/files/watch`

  Returns `{:ok, stream}` where `stream` is a `Stream` emitting maps like
  `%{"type" => "created"|"modified"|"deleted", "path" => _, "size_bytes" => _}`.

  The stream terminates when the connection drops or the caller stops consuming.
  """
  @spec watch(Client.t(), String.t(), keyword()) ::
          {:ok, Enumerable.t()} | {:error, Miosa.Error.t()}
  def watch(%Client{} = client, sandbox_id, _opts \\ []) when is_binary(sandbox_id) do
    parent = self()

    stream =
      Stream.resource(
        fn ->
          Task.start(fn ->
            Client.stream_sse(client, "/sandboxes/#{sandbox_id}/files/watch", fn event ->
              send(parent, {:file_event, event})
            end)

            send(parent, :file_watch_done)
          end)

          :streaming
        end,
        fn
          :streaming ->
            receive do
              {:file_event, event} -> {[event], :streaming}
              :file_watch_done -> {:halt, :done}
            after
              300_000 -> {:halt, :timeout}
            end

          other ->
            {:halt, other}
        end,
        fn _state -> :ok end
      )

    {:ok, stream}
  end
end
