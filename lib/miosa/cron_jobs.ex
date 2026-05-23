defmodule Miosa.CronJobs do
  @moduledoc """
  Cron jobs — scheduled work with full CRUD, pause/resume, run-now, and
  execution history.

  Mutating calls (create, update, pause, resume, run_now) send an
  `Idempotency-Key` header automatically.

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

      {:ok, job} = Miosa.CronJobs.create(client, %{
        name: "nightly-report",
        schedule: "0 4 * * *",
        url: "https://api.example.com/reports"
      })

      {:ok, _} = Miosa.CronJobs.run_now(client, job["id"])
      {:ok, history} = Miosa.CronJobs.list_executions(client, job["id"])
  """

  alias Miosa.Client

  # ── CRUD ─────────────────────────────────────────────────────────────────────

  @doc """
  List cron jobs for the authenticated tenant.

  Accepts optional filters as a keyword list or map (e.g. `:limit`, `:cursor`).
  """
  @spec list(Client.t(), keyword() | map()) :: Client.result(map())
  def list(client, filters \\ []) do
    query = filters |> normalize() |> build_query()
    Client.get(client, "/cron-jobs" <> query)
  end

  @doc "Fetch a cron job by ID."
  @spec get(Client.t(), String.t()) :: Client.result(map())
  def get(client, job_id) when is_binary(job_id) do
    Client.get(client, "/cron-jobs/" <> job_id)
  end

  @doc """
  Create a cron job.

  Required: `:name`, `:schedule` (cron expression e.g. `"0 4 * * *"`).
  Optional: `:url`, `:payload`, `:timezone`, `:enabled`, `:idempotency_key`.
  """
  @spec create(Client.t(), map()) :: Client.result(map())
  def create(client, attrs) when is_map(attrs) do
    idem = pop_idempotency(attrs)
    Client.post(client, "/cron-jobs", strip_nil(attrs), headers: [{"idempotency-key", idem}])
  end

  @doc """
  Update a cron job.

  Pass any fields to update; nil values are dropped.
  """
  @spec update(Client.t(), String.t(), map()) :: Client.result(map())
  def update(client, job_id, attrs) when is_binary(job_id) and is_map(attrs) do
    Client.patch(client, "/cron-jobs/" <> job_id, strip_nil(attrs))
  end

  @doc "Delete a cron job by ID."
  @spec delete(Client.t(), String.t()) :: Client.result(map())
  def delete(client, job_id) when is_binary(job_id) do
    Client.delete(client, "/cron-jobs/" <> job_id)
  end

  # ── Control ──────────────────────────────────────────────────────────────────

  @doc "Pause a cron job (stops future scheduled runs)."
  @spec pause(Client.t(), String.t()) :: Client.result(map())
  def pause(client, job_id) when is_binary(job_id) do
    idem = generate_idempotency_key()
    Client.post(client, "/cron-jobs/#{job_id}/pause", nil, headers: [{"idempotency-key", idem}])
  end

  @doc "Resume a paused cron job."
  @spec resume(Client.t(), String.t()) :: Client.result(map())
  def resume(client, job_id) when is_binary(job_id) do
    idem = generate_idempotency_key()
    Client.post(client, "/cron-jobs/#{job_id}/resume", nil, headers: [{"idempotency-key", idem}])
  end

  @doc "Trigger an immediate execution of a cron job outside its schedule."
  @spec run_now(Client.t(), String.t()) :: Client.result(map())
  def run_now(client, job_id) when is_binary(job_id) do
    idem = generate_idempotency_key()
    Client.post(client, "/cron-jobs/#{job_id}/run-now", nil, headers: [{"idempotency-key", idem}])
  end

  # ── Execution history ────────────────────────────────────────────────────────

  @doc "List execution history for a cron job."
  @spec list_executions(Client.t(), String.t(), keyword() | map()) :: Client.result(map())
  def list_executions(client, job_id, filters \\ []) when is_binary(job_id) do
    query = filters |> normalize() |> build_query()
    Client.get(client, "/cron-jobs/#{job_id}/executions" <> query)
  end

  @doc "Get a specific execution record for a cron job."
  @spec get_execution(Client.t(), String.t(), String.t()) :: Client.result(map())
  def get_execution(client, job_id, execution_id)
      when is_binary(job_id) and is_binary(execution_id) do
    Client.get(client, "/cron-jobs/#{job_id}/executions/#{execution_id}")
  end

  # ── Helpers ──────────────────────────────────────────────────────────────────

  defp pop_idempotency(attrs) do
    cond do
      is_map(attrs) -> Map.get(attrs, :idempotency_key) || Map.get(attrs, "idempotency_key")
      Keyword.keyword?(attrs) -> Keyword.get(attrs, :idempotency_key)
      true -> nil
    end || generate_idempotency_key()
  end

  defp generate_idempotency_key do
    16 |> :crypto.strong_rand_bytes() |> Base.encode16(case: :lower)
  end

  defp strip_nil(map) when is_map(map) do
    map
    |> Map.delete(:idempotency_key)
    |> Map.delete("idempotency_key")
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp normalize(filters) when is_list(filters), do: Map.new(filters)
  defp normalize(filters) when is_map(filters), do: filters

  defp build_query(filters) when filters == %{}, do: ""

  defp build_query(filters) do
    "?" <>
      (filters
       |> Enum.reject(fn {_k, v} -> is_nil(v) end)
       |> Enum.map(fn {k, v} -> "#{k}=#{URI.encode_www_form(to_string(v))}" end)
       |> Enum.join("&"))
  end
end
