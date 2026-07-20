defmodule Miosa.Client do
  @moduledoc """
  HTTP transport layer for the MIOSA API.

  Holds configuration and wraps `Req` for all request types: JSON API calls,
  multipart file uploads, binary downloads, and SSE streaming.

  Construct a client via `Miosa.client/2` rather than using this module directly.

  ## Options

    * `:api_key` — Required. API key starting with `msk_`.
    * `:base_url` — Override the API base URL. Defaults to `https://api.miosa.ai/api/v1`.
    * `:timeout` — Request timeout in milliseconds. Defaults to `30_000`.
    * `:receive_timeout` — Receive timeout for long-running requests. Defaults to `60_000`.
    * `:retry` — Whether to retry failed requests. Defaults to `false`.

  """

  @base_url "https://api.miosa.ai/api/v1"
  @default_timeout 30_000
  @default_receive_timeout 60_000

  # Name of the shared Finch pool. Finch is the connection-pooling HTTP
  # client that backs Req. Using a named pool — instead of Req's default
  # per-process pool — means every Miosa.Client struct shares the same
  # set of warm TCP/TLS sessions, which is what eliminates the per-call
  # TLS handshake tax. The pool is configured with HTTP/2 so sequential
  # calls multiplex on a single socket.
  @finch_pool :miosa_finch_pool

  @enforce_keys [:api_key, :base_url]
  defstruct [:api_key, :base_url, :timeout, :receive_timeout, :retry, :_req]

  @type t :: %__MODULE__{
          api_key: String.t(),
          base_url: String.t(),
          timeout: pos_integer(),
          receive_timeout: pos_integer(),
          retry: boolean(),
          _req: Req.Request.t()
        }

  @type result(type) :: {:ok, type} | {:error, Miosa.Error.t()}

  @doc """
  Builds a new `Miosa.Client` struct.

  Validates the API key format and constructs a base `Req` request with
  default headers and options pre-applied.
  """
  @spec new(String.t(), keyword()) :: t()
  def new(api_key, opts \\ []) when is_binary(api_key) do
    unless String.starts_with?(api_key, "msk_") do
      raise ArgumentError,
        message: "MIOSA API keys must start with 'msk_'. Got: #{inspect(api_key)}"
    end

    base_url = Keyword.get(opts, :base_url, @base_url)
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    receive_timeout = Keyword.get(opts, :receive_timeout, @default_receive_timeout)
    retry = Keyword.get(opts, :retry, false)

    :ok = ensure_finch_pool_started()

    # Note: when a named :finch pool is supplied, Req forbids
    # :connect_options (those must be configured on the pool itself —
    # which we do in ensure_finch_pool_started/0). Only request-level
    # options like :receive_timeout belong here.
    req =
      Req.new(
        base_url: base_url,
        headers: [
          {"authorization", "Bearer #{api_key}"},
          {"user-agent", "miosa-elixir/#{Mix.Project.config()[:version]}"},
          {"accept", "application/json"}
        ],
        receive_timeout: receive_timeout,
        retry: retry,
        finch: @finch_pool
      )

    %__MODULE__{
      api_key: api_key,
      base_url: base_url,
      timeout: timeout,
      receive_timeout: receive_timeout,
      retry: retry,
      _req: req
    }
  end

  @doc false
  # Verifies the shared Finch connection pool is running. The pool is
  # normally started by `Miosa.Application` when the :miosa app boots;
  # this function exists as a defence-in-depth fallback for callers who
  # have started the SDK in some unusual way (e.g. without the
  # application supervisor).
  @spec ensure_finch_pool_started() :: :ok
  def ensure_finch_pool_started do
    case Process.whereis(@finch_pool) do
      pid when is_pid(pid) ->
        :ok

      nil ->
        # Application supervisor not running — start a standalone pool.
        # This branch is hit when the SDK is used outside its OTP app
        # (e.g. some scripting setups). Identical config to
        # Miosa.Application.
        finch_opts = [
          name: @finch_pool,
          pools: %{
            :default => [
              size: 20,
              protocols: [:http2, :http1],
              conn_max_idle_time: 60_000,
              conn_opts: [transport_opts: [timeout: 30_000]]
            ]
          }
        ]

        case Finch.start_link(finch_opts) do
          {:ok, _pid} ->
            :ok

          {:error, {:already_started, _pid}} ->
            :ok

          {:error, reason} ->
            require Logger
            Logger.warning("miosa: failed to start Finch pool: #{inspect(reason)}")
            :ok
        end
    end
  end

  @doc """
  Performs a GET request and decodes the JSON response.
  """
  @spec get(t(), String.t(), keyword()) :: result(map())
  def get(%__MODULE__{_req: req}, path, opts \\ []) do
    req
    |> Req.get([url: path] ++ opts)
    |> handle_json_response()
  end

  @doc """
  Performs a POST request with a JSON body and decodes the response.
  """
  @spec post(t(), String.t(), map() | nil, keyword()) :: result(map())
  def post(%__MODULE__{_req: req}, path, body \\ nil, opts \\ []) do
    req_opts = [url: path] ++ opts

    req_opts =
      if body do
        req_opts ++ [json: body]
      else
        req_opts
      end

    req
    |> Req.post(req_opts)
    |> handle_json_response()
  end

  @doc """
  Performs a DELETE request and decodes the JSON response.
  """
  @spec delete(t(), String.t(), keyword()) :: result(map())
  def delete(%__MODULE__{_req: req}, path, opts \\ []) do
    req
    |> Req.delete([url: path] ++ opts)
    |> handle_json_response()
  end

  @doc """
  Performs a PATCH request with a JSON body and decodes the response.
  """
  @spec patch(t(), String.t(), map() | nil, keyword()) :: result(map())
  def patch(%__MODULE__{_req: req}, path, body \\ nil, opts \\ []) do
    req_opts = [url: path] ++ opts
    req_opts = if body, do: req_opts ++ [json: body], else: req_opts

    req
    |> Req.patch(req_opts)
    |> handle_json_response()
  end

  @doc """
  Performs a PUT request with a JSON body and decodes the response.
  """
  @spec put(t(), String.t(), map() | nil, keyword()) :: result(map())
  def put(%__MODULE__{_req: req}, path, body \\ nil, opts \\ []) do
    req_opts = [url: path] ++ opts
    req_opts = if body, do: req_opts ++ [json: body], else: req_opts

    req
    |> Req.put(req_opts)
    |> handle_json_response()
  end

  @doc """
  Performs a GET request and returns the raw binary response body.

  Used for downloading files and screenshots.
  """
  @spec get_binary(t(), String.t(), keyword()) :: result(binary())
  def get_binary(%__MODULE__{_req: req}, path, opts \\ []) do
    req
    |> Req.get([url: path, decode_body: false] ++ opts)
    |> handle_binary_response()
  end

  @doc """
  Performs a multipart POST for file uploads.

  `parts` should be a list of `{name, value}` tuples or `{name, value, opts}` tuples
  compatible with `Req`'s `:form_multipart` option. Multipart names are atoms,
  as required by Req 0.6 and later.
  """
  @spec post_multipart(t(), String.t(), list(), keyword()) :: result(map())
  def post_multipart(%__MODULE__{_req: req}, path, parts, opts \\ []) do
    req
    |> Req.post([url: path, form_multipart: parts] ++ opts)
    |> handle_json_response()
  end

  @doc """
  Opens an SSE stream and calls `callback` for each parsed event.

  The callback receives `{event_type :: String.t(), data :: String.t()}` tuples.
  The stream is consumed until the connection closes or the server sends `data: [DONE]`.

  Returns `:ok` when the stream completes or `{:error, reason}` on failure.
  """
  @spec stream_sse(t(), String.t(), function(), keyword()) :: :ok | {:error, Miosa.Error.t()}
  def stream_sse(%__MODULE__{_req: req}, path, callback, opts \\ [])
      when is_function(callback, 1) do
    req_opts =
      [
        url: path,
        decode_body: false,
        headers: [{"accept", "text/event-stream"}],
        into: :self
      ] ++ opts

    case Req.get(req, req_opts) do
      {:ok, %Req.Response{status: status}} when status in 200..299 ->
        consume_sse(callback)

      {:ok, response} ->
        {:error, Miosa.Error.from_response(response)}

      {:error, exception} ->
        {:error, Miosa.Error.from_exception(exception)}
    end
  end

  # ---------------------------------------------------------------------------
  # Private helpers
  # ---------------------------------------------------------------------------

  defp handle_json_response({:ok, %Req.Response{status: status, body: body}})
       when status in 200..299 do
    {:ok, body}
  end

  defp handle_json_response({:ok, response}) do
    {:error, Miosa.Error.from_response(response)}
  end

  defp handle_json_response({:error, exception}) do
    {:error, Miosa.Error.from_exception(exception)}
  end

  defp handle_binary_response({:ok, %Req.Response{status: status, body: body}})
       when status in 200..299 do
    {:ok, body}
  end

  defp handle_binary_response({:ok, %Req.Response{status: status, body: body} = response}) do
    # When decode_body: false, the error body may still be a JSON string — try to decode it
    decoded_response =
      case body do
        binary when is_binary(binary) ->
          case Jason.decode(binary) do
            {:ok, map} -> %{response | body: map}
            _ -> response
          end

        _ ->
          response
      end

    _ = status
    {:error, Miosa.Error.from_response(decoded_response)}
  end

  defp handle_binary_response({:error, exception}) do
    {:error, Miosa.Error.from_exception(exception)}
  end

  # Consume SSE messages from the process mailbox (Req's :into => :self pattern).
  defp consume_sse(callback) do
    consume_sse_loop(callback, _buffer = "", _current_event = nil)
  end

  defp consume_sse_loop(callback, buffer, current_event) do
    receive do
      {ref, {:data, chunk}} when is_reference(ref) ->
        {new_buffer, events} = parse_sse_chunk(buffer <> chunk)

        Enum.each(events, fn event ->
          unless event.data == "[DONE]", do: callback.(event)
        end)

        if Enum.any?(events, &(&1.data == "[DONE]")) do
          :ok
        else
          consume_sse_loop(callback, new_buffer, current_event)
        end

      {ref, :done} when is_reference(ref) ->
        # Process any remaining buffered data
        unless buffer == "" do
          {_, events} = parse_sse_chunk(buffer <> "\n\n")

          Enum.each(events, fn event ->
            unless event.data == "[DONE]", do: callback.(event)
          end)
        end

        :ok

      {ref, {:error, reason}} when is_reference(ref) ->
        {:error, %Miosa.Error{message: inspect(reason), status: nil, code: nil}}
    after
      120_000 ->
        {:error,
         %Miosa.Error{
           message: "SSE stream timed out after 120 seconds",
           status: nil,
           code: "STREAM_TIMEOUT"
         }}
    end
  end

  # Parses an SSE chunk into events, returns {remaining_buffer, [events]}.
  # Events are maps with :type and :data keys.
  defp parse_sse_chunk(chunk) do
    parts = String.split(chunk, "\n\n")

    case parts do
      [incomplete] ->
        {incomplete, []}

      [_ | _] ->
        # Last element may be incomplete
        {last, complete_parts} = List.pop_at(parts, -1)

        events =
          complete_parts
          |> Enum.map(&parse_sse_message/1)
          |> Enum.reject(&is_nil/1)

        {last, events}
    end
  end

  defp parse_sse_message(message) do
    lines = String.split(message, "\n")

    result =
      Enum.reduce(lines, %{type: "message", data: ""}, fn line, acc ->
        cond do
          String.starts_with?(line, "event:") ->
            Map.put(acc, :type, String.trim(String.slice(line, 6..-1//1)))

          String.starts_with?(line, "data:") ->
            data = String.trim(String.slice(line, 5..-1//1))
            Map.update!(acc, :data, &(&1 <> data))

          # Comments and empty lines — skip
          true ->
            acc
        end
      end)

    if result.data == "", do: nil, else: result
  end
end
