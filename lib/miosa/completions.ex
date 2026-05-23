defmodule Miosa.Completions do
  @moduledoc """
  OpenAI-compatible chat and text completion endpoints.

  Routes live under `/api/v1/intelligence/` and require an `mki_*`
  intelligence key. Streaming endpoints call `callback` for each SSE event.
  """

  alias Miosa.Client

  @doc """
  Create a text completion (POST `/intelligence/completions`).

  ## Options

    * `:stream` — When `true`, streams SSE events via `callback`. Defaults to `false`.
    * `:prompt` — Text prompt (string or list of strings).
    * Any extra key is forwarded to the API body.

  When `:stream` is `false`, returns `{:ok, response_map}`.
  When `:stream` is `true`, pass a `callback` function; returns `:ok` or `{:error, reason}`.
  """
  @spec create(Client.t(), String.t(), map(), function() | nil) ::
          Client.result(map()) | :ok | {:error, Miosa.Error.t()}
  def create(%Client{} = client, model, opts \\ %{}, callback \\ nil)
      when is_binary(model) do
    body = build_body(model, opts)

    if Map.get(opts, :stream, false) and is_function(callback, 1) do
      Client.stream_sse(client, "/intelligence/completions", callback,
        method: :post,
        json: body
      )
    else
      client
      |> Client.post("/intelligence/completions", body)
      |> unwrap()
    end
  end

  @doc """
  Create a chat completion (POST `/intelligence/chat/completions`).

  ## Parameters

    * `model` — Model ID string.
    * `messages` — List of message maps (`%{"role" => ..., "content" => ...}`).
    * `opts` — Optional extra body params (`:temperature`, `:max_tokens`, etc.).
    * `callback` — Required when `opts.stream == true`. Called with each SSE event map.

  When `:stream` is `false` (default), returns `{:ok, response_map}`.
  """
  @spec chat(Client.t(), String.t(), list(), map(), function() | nil) ::
          Client.result(map()) | :ok | {:error, Miosa.Error.t()}
  def chat(%Client{} = client, model, messages, opts \\ %{}, callback \\ nil)
      when is_binary(model) and is_list(messages) do
    body = build_body(model, Map.put(opts, :messages, messages))

    if Map.get(opts, :stream, false) and is_function(callback, 1) do
      Client.stream_sse(client, "/intelligence/chat/completions", callback,
        method: :post,
        json: body
      )
    else
      client
      |> Client.post("/intelligence/chat/completions", body)
      |> unwrap()
    end
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp build_body(model, opts) do
    base = %{"model" => model, "stream" => Map.get(opts, :stream, false)}

    opts
    |> Map.drop([:stream, "stream"])
    |> Enum.reduce(base, fn {k, v}, acc ->
      if v != nil, do: Map.put(acc, to_string(k), v), else: acc
    end)
  end

  defp unwrap({:ok, %{"choices" => _} = body}), do: {:ok, body}
  defp unwrap({:ok, %{"data" => data}}), do: {:ok, data}
  defp unwrap({:ok, body}), do: {:ok, body}
  defp unwrap(err), do: err
end
