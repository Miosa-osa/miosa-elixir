defmodule Miosa.SandboxTemplates do
  @moduledoc """
  Sandbox template management — define reusable base images for sandboxes.

  Templates are built from a `build_spec` (a declarative definition of the
  base image). Use `build_spec_schema/1` to discover the schema, `validate/2`
  to check a spec before creating a template, and `create_build/2` to trigger
  a build.

  Mutating calls (create, create_build) send an `Idempotency-Key` header
  automatically.

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

      {:ok, schema} = Miosa.SandboxTemplates.build_spec_schema(client)

      {:ok, tmpl} = Miosa.SandboxTemplates.create(client, %{
        name: "node-20-base",
        build_spec: %{runtime: "node", version: "20", packages: ["curl"]}
      })

      {:ok, build} = Miosa.SandboxTemplates.create_build(client, tmpl["id"], %{})
  """

  alias Miosa.Client

  # ── CRUD ─────────────────────────────────────────────────────────────────────

  @doc """
  List sandbox templates for the authenticated tenant.

  Options:
    * `:include_aliases` — Include template alias names. Defaults to `false`.
  """
  @spec list(Client.t(), keyword() | map()) :: Client.result(map())
  def list(client, opts \\ []) do
    query = opts |> normalize() |> build_query()
    Client.get(client, "/sandbox-templates" <> query)
  end

  @doc "Fetch a sandbox template by ID."
  @spec get(Client.t(), String.t()) :: Client.result(map())
  def get(client, template_id) when is_binary(template_id) do
    Client.get(client, "/sandbox-templates/" <> template_id)
  end

  @doc """
  Create a sandbox template.

  Required: `:name`, `:build_spec` (map). Optional: `:description`, `:metadata`,
  `:idempotency_key`.
  """
  @spec create(Client.t(), map()) :: Client.result(map())
  def create(client, attrs) when is_map(attrs) do
    idem = pop_idempotency(attrs)

    Client.post(client, "/sandbox-templates", strip_nil(attrs),
      headers: [{"idempotency-key", idem}]
    )
  end

  # ── Build spec ───────────────────────────────────────────────────────────────

  @doc "Get the JSON schema for sandbox build specs."
  @spec build_spec_schema(Client.t()) :: Client.result(map())
  def build_spec_schema(client) do
    Client.get(client, "/sandbox-templates/build-spec")
  end

  @doc """
  Validate a build spec without creating a template.

  Returns validation errors or `{:ok, result}` with the normalized spec.
  """
  @spec validate(Client.t(), map()) :: Client.result(map())
  def validate(client, build_spec) when is_map(build_spec) do
    Client.post(client, "/sandbox-templates/validate", %{build_spec: build_spec})
  end

  # ── Builds ───────────────────────────────────────────────────────────────────

  @doc "List builds for a sandbox template."
  @spec list_builds(Client.t(), String.t()) :: Client.result(map())
  def list_builds(client, template_id) when is_binary(template_id) do
    Client.get(client, "/sandbox-templates/#{template_id}/builds")
  end

  @doc """
  Trigger a new build for a sandbox template.

  Optional `attrs` may include build-time overrides. Pass `:idempotency_key`
  to supply your own idempotency key.
  """
  @spec create_build(Client.t(), String.t(), map()) :: Client.result(map())
  def create_build(client, template_id, attrs \\ %{})
      when is_binary(template_id) and is_map(attrs) do
    idem = pop_idempotency(attrs)

    Client.post(
      client,
      "/sandbox-templates/#{template_id}/builds",
      strip_nil(attrs),
      headers: [{"idempotency-key", idem}]
    )
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
