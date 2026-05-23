defmodule Miosa.OauthFlow do
  @moduledoc """
  A pending OAuth Connect flow.

  Returned by `Miosa.Secrets.connect/3`. The caller is responsible for
  surfacing `authorize_url` to the end user's browser — the SDK never
  opens a browser tab automatically.

  Once the user completes the OAuth grant, call
  `wait_for_completion/2` to poll the server until the flow either
  completes (returning the resulting secret payload) or fails.

  ## Fields

    * `:authorize_url` — URL the end user must visit to grant OAuth consent.
    * `:state` — Opaque server-issued token that identifies this flow.
    * `:provider` — Provider slug, e.g. `"github"` or `"slack"`.
    * `:client` — The `Miosa.Client` used to start the flow (retained for
      polling).
    * `:data` — Raw response payload from `POST /egress/oauth/start`.

  ## Example

      {:ok, flow} = Miosa.Secrets.connect(client, "github")
      IO.puts("Visit: " <> flow.authorize_url)
      {:ok, secret} = Miosa.OauthFlow.wait_for_completion(flow)

  """

  alias Miosa.Client

  @enforce_keys [:authorize_url, :state, :client]
  defstruct [:authorize_url, :state, :provider, :client, data: %{}]

  @type t :: %__MODULE__{
          authorize_url: String.t(),
          state: String.t(),
          provider: String.t() | nil,
          client: Client.t(),
          data: map()
        }

  @oauth_status_path "/egress/oauth/status"
  @default_timeout_ms 300_000
  @poll_interval_ms 2_000

  @doc """
  Poll `GET /egress/oauth/status?state=<state>` until the OAuth flow
  completes.

  Returns `{:ok, payload}` where `payload` is the raw status map (which
  typically includes `secret_id` and `status: "completed"`).

  Returns `{:error, reason}` on failure or denial, and
  `{:error, :timeout}` when `timeout_ms` elapses before completion.

  ## Options

    * `:timeout_ms` — milliseconds to wait before giving up. Defaults to
      `300_000` (5 minutes).
    * `:poll_interval_ms` — polling cadence in milliseconds. Defaults to
      `2_000`.
  """
  @spec wait_for_completion(t(), keyword()) :: {:ok, map()} | {:error, term()}
  def wait_for_completion(%__MODULE__{} = flow, opts \\ []) do
    timeout_ms = Keyword.get(opts, :timeout_ms, @default_timeout_ms)
    poll_interval_ms = Keyword.get(opts, :poll_interval_ms, @poll_interval_ms)
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    do_poll(flow, deadline, poll_interval_ms)
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp do_poll(%__MODULE__{client: client, state: state} = flow, deadline, interval) do
    if System.monotonic_time(:millisecond) >= deadline do
      {:error, :timeout}
    else
      case Client.get(client, @oauth_status_path, params: [state: state]) do
        {:ok, body} ->
          payload = unwrap(body)
          status = Map.get(payload, "status")

          cond do
            status in ["completed", "ready", "succeeded"] ->
              {:ok, payload}

            status in ["failed", "error", "denied"] ->
              detail = Map.get(payload, "error") || Map.get(payload, "message") || "no detail"
              {:error, "OAuth flow ended with status=#{status}: #{detail}"}

            true ->
              Process.sleep(interval)
              do_poll(flow, deadline, interval)
          end

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  # Unwrap common API envelope shapes.
  defp unwrap(%{"data" => inner}) when map_size(%{"data" => inner}) <= 2, do: inner
  defp unwrap(other), do: other
end
