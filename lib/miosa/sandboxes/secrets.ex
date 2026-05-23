defmodule Miosa.Sandboxes.Secrets do
  @moduledoc """
  Sandbox-bound view of `Miosa.Secrets`.

  Every call pre-populates `resource_id` with the sandbox's ID and sets
  `resource_type` to `"sandbox"`. This means you never have to repeat the
  sandbox ID in each call.

  ## Usage

      {:ok, sandbox} = Miosa.Sandboxes.create(client, %{name: "my-box"})

      # Bind a secret to this sandbox
      {:ok, secret} = Miosa.Sandboxes.Secrets.set(sandbox, client, %{
        name: "OPENAI_KEY",
        value: "sk-...",
        expose_as_env: "OPENAI_API_KEY"
      })

      {:ok, secrets} = Miosa.Sandboxes.Secrets.list(sandbox, client)
      {:ok, flow}    = Miosa.Sandboxes.Secrets.connect(sandbox, client, "github")

  The `sandbox` argument may be either a `Miosa.Types.Computer.t()` struct or
  a plain binary sandbox ID string.
  """

  alias Miosa.{Client, Secrets, OauthFlow}

  @resource_type "sandbox"

  # ---------------------------------------------------------------------------
  # CRUD (delegates to Miosa.Secrets with pre-scoped resource attrs)
  # ---------------------------------------------------------------------------

  @doc """
  Create a secret scoped to this sandbox.

  Merges `resource_id` and `resource_type="sandbox"` into `attrs` unless
  already present.
  """
  @spec set(map() | String.t(), Client.t(), map()) :: Client.result(map())
  def set(sandbox_or_id, %Client{} = client, attrs) when is_map(attrs) do
    rid = resource_id(sandbox_or_id)

    merged =
      attrs
      |> Map.put_new(:resource_id, rid)
      |> Map.put_new(:resource_type, @resource_type)

    Secrets.set(client, merged)
  end

  @doc """
  List secrets scoped to this sandbox.
  """
  @spec list(map() | String.t(), Client.t(), map()) :: Client.result([map()])
  def list(sandbox_or_id, %Client{} = client, filters \\ %{}) do
    rid = resource_id(sandbox_or_id)

    merged =
      filters
      |> Map.put_new(:resource_id, rid)
      |> Map.put_new(:resource_type, @resource_type)

    Secrets.list(client, merged)
  end

  @doc """
  Fetch a single secret by ID.
  """
  @spec get(map() | String.t(), Client.t(), String.t()) :: Client.result(map())
  def get(_sandbox_or_id, %Client{} = client, secret_id) when is_binary(secret_id) do
    Secrets.get(client, secret_id)
  end

  @doc """
  Rotate a secret's value.
  """
  @spec rotate(map() | String.t(), Client.t(), String.t(), map()) :: Client.result(map())
  def rotate(_sandbox_or_id, %Client{} = client, secret_id, attrs) when is_binary(secret_id) do
    Secrets.rotate(client, secret_id, attrs)
  end

  @doc """
  Delete a secret by ID.
  """
  @spec delete(map() | String.t(), Client.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def delete(_sandbox_or_id, %Client{} = client, secret_id) when is_binary(secret_id) do
    Secrets.delete(client, secret_id)
  end

  @doc """
  Start an OAuth Connect flow scoped to this sandbox.
  """
  @spec connect(map() | String.t(), Client.t(), String.t(), map()) ::
          Client.result(OauthFlow.t())
  def connect(sandbox_or_id, %Client{} = client, provider, opts \\ %{}) do
    rid = resource_id(sandbox_or_id)

    merged =
      opts
      |> Map.put_new(:resource_id, rid)
      |> Map.put_new(:resource_type, @resource_type)

    Secrets.connect(client, provider, merged)
  end

  @doc """
  List bindings scoped to this sandbox.
  """
  @spec list_bindings(map() | String.t(), Client.t(), map()) :: Client.result([map()])
  def list_bindings(sandbox_or_id, %Client{} = client, filters \\ %{}) do
    rid = resource_id(sandbox_or_id)

    merged =
      filters
      |> Map.put_new(:resource_id, rid)
      |> Map.put_new(:resource_type, @resource_type)

    Secrets.list_bindings(client, merged)
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp resource_id(%{id: id}), do: id
  defp resource_id(id) when is_binary(id), do: id
end
