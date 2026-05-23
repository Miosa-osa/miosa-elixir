defmodule Miosa.Deployments do
  @moduledoc """
  Deployments — sandbox → production publishing surface.

  Backend phase status (2026-05-15):
    * `list/2`, `get/2`, `list_builds/2`, `get_build/3`, env helpers: pre-existing
      repo flow.
    * `publish/3`, `versions.*`, `rollback/3`, `domains.*`: Phase 2B/3 target —
      returns the steady-state shape once the publish pipeline lands.
    * `publish_from_sandbox/3`: backward-compatible bridge, works today.

  All mutating calls send an `Idempotency-Key` header. Provide your own via
  the `:idempotency_key` option or one is generated automatically.

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

      {:ok, sandbox} = Miosa.Sandboxes.create(client, %{
        name: "smile-dental",
        external_workspace_id: "dental-office-123",
        external_user_id: "dr-smith-456"
      })

      # ... agent writes files, runs dev server ...

      {:ok, result} = Miosa.Deployments.publish_from_sandbox(client, sandbox.id, %{
        kind: "static",
        environment: "production",
        external_workspace_id: "dental-office-123"
      })
  """

  alias Miosa.Client

  @attr_fields ~w(external_workspace_id external_user_id external_project_id)a

  # ── List / Get / Create / Update / Delete ───────────────────────────────

  @doc """
  List deployments for the authenticated tenant.

  Accepts filters:

    * `:project_id`, `:state`, `:limit`, `:cursor`
    * `:external_workspace_id`, `:external_user_id`, `:external_project_id`
  """
  @spec list(Client.t(), keyword() | map()) :: Client.result(map())
  def list(client, filters \\ []) do
    query =
      filters
      |> normalize()
      |> build_query()

    Client.get(client, "/deployments" <> query)
  end

  @doc "Fetch a deployment by ID."
  @spec get(Client.t(), String.t()) :: Client.result(map())
  def get(client, id) when is_binary(id) do
    Client.get(client, "/deployments/" <> id)
  end

  @doc """
  Create a deployment.

  Accepts the documented Phase 2B/3 fields:

    * `:name` (required)
    * `:project_id` — if set, posts to `/projects/:id/deployments`
    * `:source_type`, `:repo_url`, `:branch`
    * `:build_command`, `:run_command`, `:auto_deploy`, `:metadata`
    * `:external_workspace_id`, `:external_user_id`, `:external_project_id`
    * `:idempotency_key`
  """
  @spec create(Client.t(), map()) :: Client.result(map())
  def create(client, attrs) when is_map(attrs) do
    project_id = Map.get(attrs, :project_id) || Map.get(attrs, "project_id")
    body = attrs |> Map.delete(:project_id) |> Map.delete("project_id") |> strip_nil()

    path =
      if project_id, do: "/projects/#{project_id}/deployments", else: "/deployments"

    idem = pop_idempotency(attrs)
    Client.post(client, path, body, headers: [{"idempotency-key", idem}])
  end

  @doc "Patch a deployment."
  @spec update(Client.t(), String.t(), map()) :: Client.result(map())
  def update(client, id, attrs) when is_binary(id) and is_map(attrs) do
    Client.patch(client, "/deployments/" <> id, strip_nil(attrs))
  end

  @doc "Delete a deployment."
  @spec delete(Client.t(), String.t()) :: Client.result(map())
  def delete(client, id) when is_binary(id) do
    Client.delete(client, "/deployments/" <> id)
  end

  # ── Publish / Rollback ──────────────────────────────────────────────────

  @doc """
  Publish a sandbox to a deployment. Phase 2B/3 endpoint.

  Required: `:source_sandbox_id`. Optional fields mirror the API contract
  (`:kind`, `:environment`, `:output_path`, `:build_command`, `:run_command`,
  `:port`, `:health_check_path`, `:data_services`, attribution).
  """
  @spec publish(Client.t(), String.t(), map()) :: Client.result(map())
  def publish(client, deployment_id, attrs) when is_binary(deployment_id) do
    body =
      attrs
      |> Map.put_new(:kind, "auto")
      |> Map.put_new(:environment, "production")
      |> strip_nil()

    idem = pop_idempotency(attrs)

    Client.post(client, "/deployments/#{deployment_id}/publish", body,
      headers: [{"idempotency-key", idem}]
    )
  end

  @doc """
  Publish through the backward-compatible bridge `/sandboxes/:id/deploy`.
  Works today. Prefer `publish/3` once the release pipeline lands.
  """
  @spec publish_from_sandbox(Client.t(), String.t(), map()) :: Client.result(map())
  def publish_from_sandbox(client, sandbox_id, attrs) when is_binary(sandbox_id) do
    body =
      attrs
      |> Map.put(:source_sandbox_id, sandbox_id)
      |> Map.put_new(:kind, "auto")
      |> Map.put_new(:environment, "production")
      |> strip_nil()

    idem = pop_idempotency(attrs)

    Client.post(client, "/sandboxes/#{sandbox_id}/deploy", body,
      headers: [{"idempotency-key", idem}]
    )
  end

  @doc """
  Roll back a deployment to an older ready version.

  If `:version_id` is omitted, the server defaults to the immediately
  previous version.
  """
  @spec rollback(Client.t(), String.t(), map()) :: Client.result(map())
  def rollback(client, deployment_id, attrs \\ %{}) when is_binary(deployment_id) do
    body = attrs |> strip_nil()
    idem = pop_idempotency(attrs)

    Client.post(client, "/deployments/#{deployment_id}/rollback", body,
      headers: [{"idempotency-key", idem}]
    )
  end

  # ── Builds (repo flow) ──────────────────────────────────────────────────

  @doc "List builds for a deployment (legacy repo flow)."
  @spec list_builds(Client.t(), String.t()) :: Client.result(map())
  def list_builds(client, deployment_id) when is_binary(deployment_id) do
    Client.get(client, "/deployments/#{deployment_id}/builds")
  end

  @doc "Get a specific build."
  @spec get_build(Client.t(), String.t(), String.t()) :: Client.result(map())
  def get_build(client, deployment_id, build_id) do
    Client.get(client, "/deployments/#{deployment_id}/builds/#{build_id}")
  end

  # ── Env ────────────────────────────────────────────────────────────────

  @doc "List env vars for a deployment."
  @spec list_env(Client.t(), String.t()) :: Client.result(map())
  def list_env(client, deployment_id) do
    Client.get(client, "/deployments/#{deployment_id}/env")
  end

  @doc """
  Set env vars on a deployment.

  Pass `vars` as a map. Optional `:environment` selects which environment.
  """
  @spec set_env(Client.t(), String.t(), map(), keyword()) :: Client.result(map())
  def set_env(client, deployment_id, vars, opts \\ []) when is_map(vars) do
    body =
      %{env: vars}
      |> maybe_put(:environment, Keyword.get(opts, :environment))

    Client.post(client, "/deployments/#{deployment_id}/env", body)
  end

  # ── Versions sub-resource ──────────────────────────────────────────────

  @doc "List versions for a deployment. Same attribution filters as `list/2`."
  @spec list_versions(Client.t(), String.t(), keyword() | map()) :: Client.result(map())
  def list_versions(client, deployment_id, filters \\ []) do
    query = filters |> normalize() |> build_query()
    Client.get(client, "/deployments/#{deployment_id}/versions" <> query)
  end

  @doc "Get a specific version."
  @spec get_version(Client.t(), String.t(), String.t()) :: Client.result(map())
  def get_version(client, deployment_id, version_id) do
    Client.get(client, "/deployments/#{deployment_id}/versions/#{version_id}")
  end

  @doc """
  Promote a specific version to active. Optional `:environment`.

  Different from `publish/3`: promote points an existing ready version at
  the active slot, no rebuild.
  """
  @spec promote_version(Client.t(), String.t(), String.t(), keyword()) ::
          Client.result(map())
  def promote_version(client, deployment_id, version_id, opts \\ []) do
    body =
      %{}
      |> maybe_put(:environment, Keyword.get(opts, :environment))

    idem = Keyword.get(opts, :idempotency_key) || generate_idempotency_key()

    Client.post(
      client,
      "/deployments/#{deployment_id}/versions/#{version_id}/promote",
      body,
      headers: [{"idempotency-key", idem}]
    )
  end

  # ── Domains sub-resource ───────────────────────────────────────────────

  @doc """
  Attach a custom domain to a deployment. Returns DNS instructions.

  Required: `:domain`. Optional: `:redirect_policy`, attribution,
  `:idempotency_key`.
  """
  @spec add_domain(Client.t(), String.t(), map()) :: Client.result(map())
  def add_domain(client, deployment_id, attrs) when is_map(attrs) do
    body = strip_nil(attrs)
    idem = pop_idempotency(attrs)

    Client.post(client, "/deployments/#{deployment_id}/domains", body,
      headers: [{"idempotency-key", idem}]
    )
  end

  @doc "List custom domains attached to a deployment."
  @spec list_domains(Client.t(), String.t(), keyword() | map()) :: Client.result(map())
  def list_domains(client, deployment_id, filters \\ []) do
    query = filters |> normalize() |> build_query()
    Client.get(client, "/deployments/#{deployment_id}/domains" <> query)
  end

  @doc "Trigger DNS + TLS verification on a pending domain."
  @spec verify_domain(Client.t(), String.t(), String.t()) :: Client.result(map())
  def verify_domain(client, deployment_id, domain_id) do
    Client.post(client, "/deployments/#{deployment_id}/domains/#{domain_id}/verify")
  end

  @doc "Detach a custom domain."
  @spec delete_domain(Client.t(), String.t(), String.t()) :: Client.result(map())
  def delete_domain(client, deployment_id, domain_id) do
    Client.delete(client, "/deployments/#{deployment_id}/domains/#{domain_id}")
  end

  # ── Helpers ────────────────────────────────────────────────────────────

  defp pop_idempotency(attrs) do
    cond do
      is_map(attrs) -> Map.get(attrs, :idempotency_key) || Map.get(attrs, "idempotency_key")
      Keyword.keyword?(attrs) -> Keyword.get(attrs, :idempotency_key)
      true -> nil
    end || generate_idempotency_key()
  end

  defp generate_idempotency_key do
    16
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
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

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  @doc false
  def attribution_fields, do: @attr_fields
end
