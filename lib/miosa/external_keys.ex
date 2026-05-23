defmodule Miosa.ExternalKeys do
  @moduledoc """
  External BYOK keys — Anthropic, OpenAI, Google, Groq, and similar.

  Keys are stored encrypted per-user and consumed by dashboard features
  (Builder, Optimal, etc.). The backend indexes external keys by `provider`,
  not by a surrogate ID.

  ## Example

      client = Miosa.client(System.fetch_env!("MIOSA_API_KEY"))

      {:ok, _} = Miosa.ExternalKeys.create(client, "anthropic", "sk-ant-...")
      {:ok, keys} = Miosa.ExternalKeys.list(client)
  """

  alias Miosa.Client

  @doc "List all configured external provider keys."
  @spec list(Client.t()) :: Client.result(map())
  def list(client) do
    Client.get(client, "/external-keys")
  end

  @doc """
  Register an external provider key.

  `provider` — e.g. `"anthropic"`, `"openai"`, `"google"`, `"groq"`.
  `key` — the raw secret key string.
  `attrs` — optional additional fields accepted by the API.
  """
  @spec create(Client.t(), String.t(), String.t(), map()) :: Client.result(map())
  def create(client, provider, key, attrs \\ %{})
      when is_binary(provider) and is_binary(key) and is_map(attrs) do
    body =
      attrs
      |> strip_nil()
      |> Map.merge(%{provider: provider, key: key})

    Client.post(client, "/external-keys", body)
  end

  @doc "Resolve (preview) the stored key for a provider."
  @spec resolve(Client.t(), String.t()) :: Client.result(map())
  def resolve(client, provider) when is_binary(provider) do
    Client.get(client, "/external-keys/#{provider}/resolve")
  end

  @doc "Delete the stored key for a provider."
  @spec delete(Client.t(), String.t()) :: Client.result(map())
  def delete(client, provider) when is_binary(provider) do
    Client.delete(client, "/external-keys/" <> provider)
  end

  # ── Helpers ───────────────────────────────────────────────────────────────────

  defp strip_nil(map) when is_map(map) do
    map
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end
end
