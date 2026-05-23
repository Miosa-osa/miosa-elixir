defmodule Miosa.Sandboxes.Network do
  @moduledoc """
  Sandbox-bound view of `Miosa.Network`.

  Every call pre-populates `resource_id` with the sandbox's ID and sets
  `resource_type` to `"sandbox"`.

  ## Usage

      {:ok, sandbox} = Miosa.Sandboxes.create(client, %{name: "my-box"})

      {:ok, rule}   = Miosa.Sandboxes.Network.allow(sandbox, client, "api.github.com")
      {:ok, rule}   = Miosa.Sandboxes.Network.deny(sandbox, client, "bad.host.io")
      {:ok, policy} = Miosa.Sandboxes.Network.lockdown(sandbox, client)
      {:ok, policy} = Miosa.Sandboxes.Network.observe(sandbox, client)
      {:ok, items}  = Miosa.Sandboxes.Network.suggestions(sandbox, client)
      {:ok, rules}  = Miosa.Sandboxes.Network.rules(sandbox, client)

  The `sandbox` argument may be either a `Miosa.Types.Computer.t()` struct or
  a plain binary sandbox ID string.
  """

  alias Miosa.{Client, Network}

  @resource_type "sandbox"

  @doc """
  Add an `allow` rule for `host`, scoped to this sandbox.
  """
  @spec allow(map() | String.t(), Client.t(), String.t(), keyword()) :: Client.result(map())
  def allow(sandbox_or_id, %Client{} = client, host, opts \\ []) when is_binary(host) do
    rid = resource_id(sandbox_or_id)

    merged =
      opts
      |> Keyword.put_new(:resource_id, rid)
      |> Keyword.put_new(:resource_type, @resource_type)

    Network.allow(client, host, merged)
  end

  @doc """
  Add a `deny` rule for `host`, scoped to this sandbox.
  """
  @spec deny(map() | String.t(), Client.t(), String.t(), keyword()) :: Client.result(map())
  def deny(sandbox_or_id, %Client{} = client, host, opts \\ []) when is_binary(host) do
    rid = resource_id(sandbox_or_id)

    merged =
      opts
      |> Keyword.put_new(:resource_id, rid)
      |> Keyword.put_new(:resource_type, @resource_type)

    Network.deny(client, host, merged)
  end

  @doc """
  List allowlist rules for this sandbox.
  """
  @spec rules(map() | String.t(), Client.t(), keyword()) :: Client.result([map()])
  def rules(sandbox_or_id, %Client{} = client, filters \\ []) do
    rid = resource_id(sandbox_or_id)

    merged =
      filters
      |> Keyword.put_new(:resource_id, rid)
      |> Keyword.put_new(:resource_type, @resource_type)

    Network.rules(client, nil, merged)
  end

  @doc """
  Delete an allowlist rule by ID.
  """
  @spec remove_rule(map() | String.t(), Client.t(), String.t()) ::
          :ok | {:error, Miosa.Error.t()}
  def remove_rule(_sandbox_or_id, %Client{} = client, rule_id) when is_binary(rule_id) do
    Network.remove_rule(client, rule_id)
  end

  @doc """
  Set the policy to `mode=enforce` for this sandbox — denied requests are blocked.
  """
  @spec lockdown(map() | String.t(), Client.t(), keyword()) :: Client.result(map())
  def lockdown(sandbox_or_id, %Client{} = client, opts \\ []) do
    rid = resource_id(sandbox_or_id)

    merged =
      opts
      |> Keyword.put_new(:resource_id, rid)
      |> Keyword.put_new(:resource_type, @resource_type)

    Network.lockdown(client, merged)
  end

  @doc """
  Set the policy to `mode=audit_only` for this sandbox — log but do not block.
  """
  @spec observe(map() | String.t(), Client.t(), keyword()) :: Client.result(map())
  def observe(sandbox_or_id, %Client{} = client, opts \\ []) do
    rid = resource_id(sandbox_or_id)

    merged =
      opts
      |> Keyword.put_new(:resource_id, rid)
      |> Keyword.put_new(:resource_type, @resource_type)

    Network.observe(client, merged)
  end

  @doc """
  Return AI-generated allowlist suggestions for this sandbox.
  """
  @spec suggestions(map() | String.t(), Client.t(), keyword()) :: Client.result([map()])
  def suggestions(sandbox_or_id, %Client{} = client, opts \\ []) do
    rid = resource_id(sandbox_or_id)

    merged =
      opts
      |> Keyword.put_new(:resource_id, rid)
      |> Keyword.put_new(:resource_type, @resource_type)

    Network.suggestions(client, merged)
  end

  @doc """
  List egress policies scoped to this sandbox.
  """
  @spec policies(map() | String.t(), Client.t(), keyword()) :: Client.result([map()])
  def policies(sandbox_or_id, %Client{} = client, filters \\ []) do
    rid = resource_id(sandbox_or_id)

    merged =
      filters
      |> Keyword.put_new(:resource_id, rid)
      |> Keyword.put_new(:resource_type, @resource_type)

    Network.policies(client, merged)
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp resource_id(%{id: id}), do: id
  defp resource_id(id) when is_binary(id), do: id
end
