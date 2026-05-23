defmodule Miosa.Embeddings do
  @moduledoc """
  OpenAI-compatible embedding vectors.

  Routes live under `/api/v1/intelligence/embeddings` and require an
  `mki_*` intelligence key.
  """

  alias Miosa.Client

  @doc """
  Create one or more embedding vectors (POST `/intelligence/embeddings`).

  `input` may be a string or list of strings.

  Returns the full OpenAI-envelope response `%{"object" => "list", "data" => [...]}`.
  """
  @spec create(Client.t(), String.t() | list(), String.t(), map()) :: Client.result(map())
  def create(%Client{} = client, input, model, opts \\ %{})
      when (is_binary(input) or is_list(input)) and is_binary(model) do
    body =
      opts
      |> Enum.reduce(%{"input" => input, "model" => model}, fn {k, v}, acc ->
        if v != nil, do: Map.put(acc, to_string(k), v), else: acc
      end)

    Client.post(client, "/intelligence/embeddings", body)
  end
end
