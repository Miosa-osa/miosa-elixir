defmodule Miosa.Sandboxes do
  @moduledoc """
  Sandboxes — a thin helper over `Miosa.Computers` that defaults
  `template_type` to `"miosa-sandbox"` (ephemeral code-exec rootfs, no
  desktop).

  Mirrors the one-resource product model used by E2B and Daytona: the
  computer is the single resource type, and `template_type` selects its
  flavour. A sandbox is just a computer with the lightweight template;
  every other module (`Miosa.Computer`, `Miosa.Exec`, `Miosa.Files`,
  `Miosa.Desktop`) works identically.

  ## Example

      client = Miosa.client("msk_u_...")

      {:ok, sandbox} = Miosa.Sandboxes.create(client, %{name: "quick-exec"})
      :ok = Miosa.Computer.start(client, sandbox.id)
      {:ok, %{output: out}} = Miosa.Exec.run(client, sandbox.id, command: "echo hi")
      :ok = Miosa.Computer.destroy(client, sandbox.id)

  """

  alias Miosa.Client

  @sandbox_template "miosa-sandbox"

  @doc """
  Template slug used for the lightweight code-exec sandbox rootfs.
  """
  @spec template() :: String.t()
  def template, do: @sandbox_template

  @doc """
  Create a sandbox — a computer provisioned with the `miosa-sandbox` template.

  Accepts the same attributes as `Miosa.Computers.create/2`; the
  `template_type` key defaults to `"miosa-sandbox"` when omitted.

  ## White-label attribution

  Pass `:external_workspace_id`, `:external_user_id`, `:external_project_id`
  to tag the sandbox with your platform's customer/user/project IDs. These
  fields never authorize anything — tenancy is always derived server-side
  from the API key — but they let your list/usage APIs group by attribution.

      {:ok, sandbox} = Miosa.Sandboxes.create(client, %{
        name: "smile-dental",
        external_workspace_id: "dental-office-123",
        external_user_id: "dr-smith-456",
        external_project_id: "landing-page-789"
      })

  """
  @spec create(Client.t(), map()) :: Client.result(Miosa.Types.Computer.t())
  def create(client, attrs) when is_map(attrs) do
    attrs = stringify_keys(attrs)
    idempotency_key = Map.get(attrs, "idempotency_key")

    template_id =
      Map.get(attrs, "template_id") || Map.get(attrs, "template_type") || @sandbox_template

    body =
      attrs
      |> Map.drop(["idempotency_key", "template_type"])
      |> Map.put("template_id", template_id)

    body =
      case resolve_size!(body) do
        nil -> body
        size -> Map.put(body, "size", size)
      end

    opts =
      if is_binary(idempotency_key) and idempotency_key != "" do
        [headers: [{"idempotency-key", idempotency_key}]]
      else
        []
      end

    client
    |> Client.post("/sandboxes", body, opts)
    |> unwrap_data()
  end

  @doc """
  List native sandboxes.
  """
  @spec list(Client.t()) :: Client.result([Miosa.Types.Computer.t()])
  def list(client) do
    client
    |> Client.get("/sandboxes")
    |> unwrap_list()
  end

  @doc """
  Get a native sandbox by ID.
  """
  @spec get(Client.t(), String.t()) :: Client.result(Miosa.Types.Computer.t())
  def get(client, id), do: client |> Client.get("/sandboxes/#{id}") |> unwrap_data()

  @doc """
  Destroy a sandbox. Alias for `Miosa.Computers.delete/2`.
  """
  @spec delete(Client.t(), String.t()) :: Client.result(map())
  def delete(client, id), do: Client.delete(client, "/sandboxes/#{id}")

  @doc "Replace the activity timeout and reset the sandbox deadline."
  @spec extend(Client.t(), String.t(), pos_integer()) :: Client.result(map())
  def extend(client, id, timeout_sec) when is_integer(timeout_sec) and timeout_sec > 0 do
    client
    |> Client.post("/sandboxes/#{id}/extend", %{"timeout_sec" => timeout_sec})
    |> unwrap_data()
  end

  def extend(client, id, nil) do
    client
    |> Client.post("/sandboxes/#{id}/extend", %{})
    |> unwrap_data()
  end

  @doc "Return measured runtime and timeout visibility for a sandbox."
  @spec usage(Client.t(), String.t()) :: Client.result(map())
  def usage(client, id), do: client |> Client.get("/sandboxes/#{id}/usage") |> unwrap_data()

  @doc "Stop a sandbox while preserving state according to its persistence policy."
  @spec stop(Client.t(), String.t()) :: Client.result(map())
  def stop(client, id), do: lifecycle(client, id, "stop")

  @doc "Pause a sandbox for later resume."
  @spec pause(Client.t(), String.t()) :: Client.result(map())
  def pause(client, id), do: lifecycle(client, id, "pause")

  @doc "Resume a paused sandbox."
  @spec resume(Client.t(), String.t()) :: Client.result(map())
  def resume(client, id), do: lifecycle(client, id, "resume")

  @spec resume(Client.t(), String.t(), keyword()) :: Client.result(map())
  def resume(client, id, opts) when is_list(opts) do
    idempotency_key = Keyword.get(opts, :idempotency_key)

    request_opts =
      if is_binary(idempotency_key) and idempotency_key != "" do
        [headers: [{"idempotency-key", idempotency_key}]]
      else
        []
      end

    client
    |> Client.post("/sandboxes/#{id}/resume", %{}, request_opts)
    |> unwrap_data()
  end

  @doc "Create a retained point-in-time sandbox checkpoint."
  @spec create_snapshot(Client.t(), String.t(), map()) :: Client.result(map())
  def create_snapshot(client, id, attrs \\ %{}) when is_map(attrs) do
    body =
      attrs
      |> stringify_keys()
      |> Map.take([
        "comment",
        "keep",
        "retention_seconds",
        "expiration_seconds",
        "expiration_days"
      ])

    client
    |> Client.post("/sandboxes/#{id}/snapshots", body)
    |> unwrap_data()
  end

  @doc "List non-deleted checkpoints for a sandbox."
  @spec list_snapshots(Client.t(), String.t()) :: Client.result([map()])
  def list_snapshots(client, id) do
    client
    |> Client.get("/sandboxes/#{id}/snapshots")
    |> unwrap_data()
  end

  @doc "Restore a sandbox from a ready, unexpired checkpoint."
  @spec restore_snapshot(Client.t(), String.t(), String.t()) :: Client.result(map())
  def restore_snapshot(client, id, snapshot_id) do
    client
    |> Client.post("/sandboxes/#{id}/restore/#{snapshot_id}", %{})
    |> unwrap_data()
  end

  @doc "Retire a sandbox checkpoint."
  @spec delete_snapshot(Client.t(), String.t(), String.t()) :: Client.result(map())
  def delete_snapshot(client, id, snapshot_id),
    do: Client.delete(client, "/sandboxes/#{id}/snapshots/#{snapshot_id}")

  @doc """
  Return the readiness-probe state for a sandbox
  (GET `/sandboxes/:sandbox_id/readiness`).

  Useful to poll after creation before issuing exec commands.
  """
  @spec readiness(Client.t(), String.t()) :: Client.result(map())
  def readiness(client, sandbox_id) when is_binary(sandbox_id) do
    case Client.get(client, "/sandboxes/#{sandbox_id}/readiness") do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, body} -> {:ok, body}
      err -> err
    end
  end

  @doc """
  Block until the sandbox reports ready, or `timeout` seconds elapse.

  ## Options

    * `:timeout` — seconds to wait. Defaults to `30`.
    * `:stream`  — when `true` (the default) the SDK first attempts the
      server-side SSE endpoint `GET /sandboxes/:id/readiness/stream` which
      pushes `event: ready` as soon as the sandbox boots (and immediately if
      it is already ready). When `false` the SDK only polls.

  Returns `{:ok, true}` once ready, `{:ok, false}` on the server-emitted
  `event: timeout` frame or when the local timeout elapses before ready.

  If the SSE endpoint returns 404 (server pre-dates the streaming endpoint)
  this transparently falls back to polling `readiness/2` every 10 ms.
  """
  @spec wait_until_ready(Client.t(), String.t(), keyword()) ::
          {:ok, boolean()} | {:error, Miosa.Error.t()}
  def wait_until_ready(client, sandbox_id, opts \\ []) when is_binary(sandbox_id) do
    timeout = Keyword.get(opts, :timeout, 30)
    use_stream = Keyword.get(opts, :stream, true)

    cond do
      use_stream ->
        case try_readiness_stream(client, sandbox_id, timeout) do
          :ready -> {:ok, true}
          :server_timeout -> {:ok, false}
          :fallback -> poll_until_ready(client, sandbox_id, timeout)
        end

      true ->
        poll_until_ready(client, sandbox_id, timeout)
    end
  end

  # ── Helpers ──────────────────────────────────────────────────────────

  # Opens the SSE readiness stream and returns:
  #   :ready          — server emitted event: ready
  #   :server_timeout — server emitted event: timeout
  #   :fallback       — endpoint unavailable (404) or transport error; the
  #                     caller should poll instead.
  #
  # This consumes the stream inline (no Task) by issuing a Req call with
  # ``into: :self`` and pattern-matching the raw Finch messages. The
  # generic ``Client.stream_sse/4`` is not used because we need to peek
  # at event names and at the HTTP status (404 → fast fallback).
  defp try_readiness_stream(client, sandbox_id, timeout) do
    path = "/sandboxes/#{sandbox_id}/readiness/stream"

    req_opts = [
      url: path,
      decode_body: false,
      headers: [{"accept", "text/event-stream"}],
      into: :self,
      receive_timeout: round((timeout + 5) * 1000)
    ]

    case Req.get(client._req, req_opts) do
      {:ok, %Req.Response{status: 404}} ->
        :fallback

      {:ok, %Req.Response{status: status}} when status not in 200..299 ->
        :fallback

      {:ok, %Req.Response{status: status}} when status in 200..299 ->
        consume_readiness_stream("", round((timeout + 5) * 1000))

      {:error, _exception} ->
        :fallback
    end
  end

  # Pull SSE chunks from the calling-process mailbox until we observe either
  # ``event: ready`` or ``event: timeout``. Returns ``:fallback`` if the
  # stream terminates without one, or if no data arrives within the
  # mailbox-receive deadline.
  defp consume_readiness_stream(buffer, mailbox_timeout_ms) do
    receive do
      {{_pool, _pid}, {:data, chunk}} ->
        new_buffer = buffer <> chunk

        case scan_for_terminal_event(new_buffer) do
          {:ready, _rest} -> :ready
          {:server_timeout, _rest} -> :server_timeout
          {:cont, rest} -> consume_readiness_stream(rest, mailbox_timeout_ms)
        end

      {{_pool, _pid}, :done} ->
        :fallback

      {{_pool, _pid}, {:error, _reason}} ->
        :fallback
    after
      mailbox_timeout_ms -> :fallback
    end
  end

  # Parses the buffer one ``\n``-terminated line at a time. Returns:
  #   {:ready, leftover}          on event: ready
  #   {:server_timeout, leftover} on event: timeout
  #   {:cont, leftover}           when no terminal event has appeared yet
  defp scan_for_terminal_event(buffer) do
    case :binary.split(buffer, "\n") do
      [^buffer] ->
        # No complete line yet — keep buffering.
        {:cont, buffer}

      [line, rest] ->
        cond do
          String.starts_with?(line, "event: ready") or
              String.starts_with?(line, "event:ready") ->
            {:ready, rest}

          String.starts_with?(line, "event: timeout") or
              String.starts_with?(line, "event:timeout") ->
            {:server_timeout, rest}

          true ->
            scan_for_terminal_event(rest)
        end
    end
  end

  defp poll_until_ready(client, sandbox_id, timeout) do
    deadline = System.monotonic_time(:millisecond) + round(timeout * 1000)
    do_poll(client, sandbox_id, deadline)
  end

  defp do_poll(client, sandbox_id, deadline) do
    cond do
      System.monotonic_time(:millisecond) >= deadline ->
        {:ok, false}

      true ->
        case readiness(client, sandbox_id) do
          {:ok, data} ->
            if ready?(data) do
              {:ok, true}
            else
              Process.sleep(10)
              do_poll(client, sandbox_id, deadline)
            end

          {:error, _} ->
            Process.sleep(10)
            do_poll(client, sandbox_id, deadline)
        end
    end
  end

  defp ready?(%{"ready" => true}), do: true
  defp ready?(%{"status" => "ready"}), do: true
  defp ready?(%{ready: true}), do: true
  defp ready?(%{status: "ready"}), do: true
  defp ready?(_), do: false

  defp lifecycle(client, id, action) do
    client
    |> Client.post("/sandboxes/#{id}/#{action}", %{})
    |> unwrap_data()
  end

  defp unwrap_data({:ok, %{"data" => data}}), do: {:ok, data}
  defp unwrap_data(result), do: result

  defp unwrap_list({:ok, %{"data" => data}}) when is_list(data), do: {:ok, data}
  defp unwrap_list({:ok, %{"sandboxes" => data}}) when is_list(data), do: {:ok, data}
  defp unwrap_list({:ok, data}) when is_list(data), do: {:ok, data}
  defp unwrap_list(result), do: result

  defp stringify_keys(map) do
    Map.new(map, fn {key, value} -> {to_string(key), value} end)
  end

  defp resolve_size!(body) do
    contracts = %{
      "xs" => {1, 2_048, 10_240},
      "small" => {2, 4_096, 10_240},
      "medium" => {4, 8_192, 20_480},
      "large" => {8, 16_384, 40_960},
      "xl" => {16, 32_768, 81_920}
    }

    disk = Map.get(body, "disk_size_mb") || Map.get(body, "disk_mb")
    resources = {Map.get(body, "cpu_count"), Map.get(body, "memory_mb"), disk}
    supplied = resources |> Tuple.to_list() |> Enum.count(&(not is_nil(&1)))
    requested = Map.get(body, "size")

    case {supplied, requested} do
      {0, nil} ->
        nil

      {0, size} ->
        validate_named_size!(contracts, size)

      {3, size} ->
        match_resource_contract!(contracts, resources, size)

      _ ->
        raise ArgumentError,
              "raw sandbox resources require cpu_count, memory_mb, and disk_size_mb together"
    end
  end

  defp validate_named_size!(contracts, size) do
    if Map.has_key?(contracts, size) do
      size
    else
      raise ArgumentError, "unknown sandbox size #{inspect(size)}"
    end
  end

  defp match_resource_contract!(contracts, resources, requested) do
    case Enum.find(contracts, fn {_size, contract} -> contract == resources end) do
      {size, _} when is_nil(requested) or size == requested ->
        size

      {size, _} ->
        raise ArgumentError, "raw sandbox resources match #{size}, not #{requested}"

      nil ->
        raise ArgumentError, "raw sandbox resources must match a named size contract"
    end
  end

  @doc """
  Fork a sandbox from an existing snapshot or a running sandbox.

  POST `/api/v1/sandboxes/:id/fork`

  ## Options
    * `:snapshot_id`     — optional snapshot to fork from.
    * `:name`            — name for the new sandbox.
    * `:external_user_id` — attribution for the forked sandbox.

  Returns the new sandbox object.
  """
  @spec fork(Client.t(), String.t(), keyword()) :: Client.result(map())
  def fork(%Client{} = client, sandbox_id, opts \\ []) when is_binary(sandbox_id) do
    idempotency_key = Keyword.get(opts, :idempotency_key)

    body =
      opts
      |> Keyword.take([
        :snapshot_id,
        :name,
        :external_user_id,
        :timeout_sec,
        :template_id
      ])
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new(fn {k, v} -> {Atom.to_string(k), v} end)

    request_opts =
      if is_binary(idempotency_key) and idempotency_key != "" do
        [headers: [{"idempotency-key", idempotency_key}]]
      else
        []
      end

    case Client.post(client, "/sandboxes/#{sandbox_id}/fork", body, request_opts) do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, body} -> {:ok, body}
      err -> err
    end
  end

  @doc """
  Update mutable sandbox fields.

  Wraps `PATCH /api/v1/sandboxes/:id`. Accepted keys:
  `:name`, `:slug`, `:tags`, `:metadata`, `:always_on`,
  `:timeout_sec`, `:idle_timeout_sec`.

  Returns the updated sandbox map on success.
  """
  @spec update(Client.t(), String.t(), map()) :: Client.result(map())
  def update(client, sandbox_id, attrs) when is_binary(sandbox_id) and is_map(attrs) do
    allowed = ~w(name slug tags metadata always_on timeout_sec idle_timeout_sec)a

    body =
      attrs
      |> Map.take(allowed)
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new(fn {k, v} -> {Atom.to_string(k), v} end)

    case Client.patch(client, "/sandboxes/#{sandbox_id}", body) do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, body} -> {:ok, body}
      err -> err
    end
  end

  @doc """
  Mint a short-lived preview token for a sandbox.

  Wraps `POST /api/v1/sandboxes/:id/preview-token`.

  ## Options

    * `:expires_in` — token lifetime in seconds. Defaults to `3600`.
    * `:scope`      — token scope string. Defaults to `"read"`.

  Returns `{:ok, %{"token" => _, "url" => _, "expires_at" => _, "scope" => _}}`.
  """
  @spec preview_token(Client.t(), String.t(), keyword()) :: Client.result(map())
  def preview_token(client, sandbox_id, opts \\ []) when is_binary(sandbox_id) do
    body = %{
      "expires_in" => Keyword.get(opts, :expires_in, 3600),
      "scope" => Keyword.get(opts, :scope, "read")
    }

    case Client.post(client, "/sandboxes/#{sandbox_id}/preview-token", body) do
      {:ok, %{"data" => data}} -> {:ok, data}
      {:ok, body} -> {:ok, body}
      err -> err
    end
  end
end
