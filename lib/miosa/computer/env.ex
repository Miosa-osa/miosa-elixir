defmodule Miosa.Computer.Env do
  @moduledoc """
  Encrypted env-var CRUD scoped to one computer.

    * `GET    /computers/:id/env`          — list/2
    * `POST   /computers/:id/env`          — set/4
    * `PATCH  /computers/:id/env/:name`    — update/4
    * `DELETE /computers/:id/env/:name`    — delete/3
    * `bulk_set/3` — convenience wrapper over set/4
  """

  alias Miosa.Client

  @doc """
  List all env vars for a computer (GET `/computers/:computer_id/env`).

  Values may be masked depending on server policy.
  """
  @spec list(Client.t(), String.t()) :: Client.result(list())
  def list(%Client{} = client, computer_id) when is_binary(computer_id) do
    case Client.get(client, "/computers/#{computer_id}/env") do
      {:ok, body} -> {:ok, unwrap_list(body)}
      err -> err
    end
  end

  @doc """
  Create a new env var (POST `/computers/:computer_id/env`).

  Use `update/4` to change an existing one.
  """
  @spec set(Client.t(), String.t(), String.t(), String.t()) :: Client.result(map())
  def set(%Client{} = client, computer_id, name, value)
      when is_binary(computer_id) and is_binary(name) and is_binary(value) do
    client
    |> Client.post("/computers/#{computer_id}/env", %{"name" => name, "value" => value})
    |> unwrap()
  end

  @doc """
  Patch the value of an existing env var (PATCH `/computers/:computer_id/env/:name`).
  """
  @spec update(Client.t(), String.t(), String.t(), String.t()) :: Client.result(map())
  def update(%Client{} = client, computer_id, name, value)
      when is_binary(computer_id) and is_binary(name) and is_binary(value) do
    client
    |> Client.patch("/computers/#{computer_id}/env/#{name}", %{"value" => value})
    |> unwrap()
  end

  @doc """
  Delete an env var by name (DELETE `/computers/:computer_id/env/:name`).
  """
  @spec delete(Client.t(), String.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def delete(%Client{} = client, computer_id, name)
      when is_binary(computer_id) and is_binary(name) do
    case Client.delete(client, "/computers/#{computer_id}/env/#{name}") do
      {:ok, _} -> :ok
      err -> err
    end
  end

  @doc """
  Convenience: create one env var per entry in `env` map.

  Falls back to N individual `set/4` calls (no bulk backend endpoint yet).
  Returns a list of results in the same order as `Map.to_list(env)`.
  """
  @spec bulk_set(Client.t(), String.t(), %{String.t() => String.t()}) ::
          {:ok, list()} | {:error, Miosa.Error.t()}
  def bulk_set(%Client{} = client, computer_id, env)
      when is_binary(computer_id) and is_map(env) do
    results =
      Enum.map(env, fn {name, value} ->
        set(client, computer_id, name, value)
      end)

    errors = Enum.filter(results, &match?({:error, _}, &1))

    if errors == [] do
      {:ok, Enum.map(results, fn {:ok, v} -> v end)}
    else
      List.first(errors)
    end
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp unwrap_list(%{"data" => list}) when is_list(list), do: list
  defp unwrap_list(%{"env" => list}) when is_list(list), do: list
  defp unwrap_list(%{"items" => list}) when is_list(list), do: list
  defp unwrap_list(list) when is_list(list), do: list
  defp unwrap_list(_), do: []

  defp unwrap({:ok, %{"data" => data}}), do: {:ok, data}
  defp unwrap({:ok, body}), do: {:ok, body}
  defp unwrap(err), do: err
end
