defmodule Miosa.Files do
  @moduledoc """
  Upload, download, list, and manage files inside a MIOSA computer.

  File operations interact with the computer's filesystem via the MIOSA API.
  Paths are absolute paths inside the VM (e.g. `"/home/user/myfile.txt"`).

  ## Example

      # Upload a local file
      :ok = Miosa.Files.upload(client, computer_id, "./local.txt", "/home/user/remote.txt")

      # Download a file
      {:ok, content} = Miosa.Files.download(client, computer_id, "/home/user/remote.txt")
      File.write!("local_copy.txt", content)

      # List directory contents
      {:ok, entries} = Miosa.Files.list(client, computer_id, "/home/user")
      Enum.each(entries, fn e -> IO.puts("\#{e.type}: \#{e.name}") end)

      # Get a temporary download URL
      {:ok, export} = Miosa.Files.export(client, computer_id, "/home/user/report.pdf")
      IO.puts("Download at: \#{export.url}")

      # Delete a file
      :ok = Miosa.Files.delete(client, computer_id, "/home/user/old.txt")

  """

  alias Miosa.{Client, Types}

  @doc """
  Uploads a local file to the computer at the given remote path.

  `local_path` can be:
  - A filesystem path string (`"./myfile.txt"`)
  - A `{:binary, content, filename}` tuple for in-memory content

  ## Options

    * `:create_dirs` — Create parent directories if they don't exist. Defaults to `true`.

  """
  @spec upload(
          Client.t(),
          String.t(),
          String.t() | {:binary, binary(), String.t()},
          String.t(),
          keyword()
        ) ::
          :ok | {:error, Miosa.Error.t()}
  def upload(%Client{} = client, computer_id, local_path, remote_path, opts \\ [])
      when is_binary(remote_path) do
    create_dirs = Keyword.get(opts, :create_dirs, true)

    {file_content, filename} = read_upload_source(local_path)

    parts = [
      {"file", {file_content, filename: filename, content_type: "application/octet-stream"}},
      {"path", remote_path},
      {"create_dirs", to_string(create_dirs)}
    ]

    client
    |> Client.post_multipart("/computers/#{computer_id}/files/upload", parts)
    |> to_ok()
  end

  @doc """
  Downloads a file from the computer and returns its binary content.

  Returns `{:ok, binary()}` where `binary()` is the raw file bytes.
  """
  @spec download(Client.t(), String.t(), String.t()) :: Client.result(binary())
  def download(%Client{} = client, computer_id, remote_path) when is_binary(remote_path) do
    Client.get_binary(client, "/computers/#{computer_id}/files/download",
      params: %{path: remote_path}
    )
  end

  @doc """
  Downloads a file and writes it to a local path.

  Returns `:ok` on success or `{:error, reason}` on failure.
  `reason` may be a `Miosa.Error` (API failure) or `File.Error` (filesystem write failure).
  """
  @spec download_to(Client.t(), String.t(), String.t(), String.t()) ::
          :ok | {:error, Miosa.Error.t() | File.Error.t()}
  def download_to(%Client{} = client, computer_id, remote_path, local_path) do
    case download(client, computer_id, remote_path) do
      {:ok, content} -> File.write(local_path, content)
      {:error, _} = err -> err
    end
  end

  @doc """
  Lists the contents of a directory on the computer.

  Returns a list of `Miosa.Types.FileEntry` structs, each with `:name`,
  `:path`, `:type` (`:file`, `:directory`, `:symlink`), `:size`, and `:modified_at`.
  """
  @spec list(Client.t(), String.t(), String.t()) :: Client.result([Types.FileEntry.t()])
  def list(%Client{} = client, computer_id, path \\ "/home/user") when is_binary(path) do
    case Client.get(client, "/computers/#{computer_id}/files/list", params: %{path: path}) do
      {:ok, body} ->
        entries =
          body
          |> get_list()
          |> Enum.map(&Types.FileEntry.from_map/1)

        {:ok, entries}

      {:error, _} = err ->
        err
    end
  end

  @doc """
  Generates a temporary signed download URL for a file on the computer.

  The URL is publicly accessible for a limited time (typically 15–60 minutes).
  Useful for sharing files without streaming through the API.

  Returns `{:ok, Miosa.Types.ExportResult.t()}` with `:url` and `:expires_at`.
  """
  @spec export(Client.t(), String.t(), String.t()) :: Client.result(Types.ExportResult.t())
  def export(%Client{} = client, computer_id, remote_path) when is_binary(remote_path) do
    case Client.post(client, "/computers/#{computer_id}/files/export", %{path: remote_path}) do
      {:ok, body} -> {:ok, Types.ExportResult.from_map(body)}
      {:error, _} = err -> err
    end
  end

  @doc """
  Deletes a file or directory on the computer.

  ## Options

    * `:recursive` — Delete directories recursively. Defaults to `false`.

  """
  @spec delete(Client.t(), String.t(), String.t(), keyword()) :: :ok | {:error, Miosa.Error.t()}
  def delete(%Client{} = client, computer_id, remote_path, opts \\ [])
      when is_binary(remote_path) do
    recursive = Keyword.get(opts, :recursive, false)

    client
    |> Client.delete("/computers/#{computer_id}/files",
      params: %{path: remote_path, recursive: recursive}
    )
    |> to_ok()
  end

  @doc """
  Writes string or binary content directly to a file on the computer.

  Convenience wrapper around `upload/5` for in-memory content.

  ## Example

      :ok = Miosa.Files.write(client, computer_id, "/home/user/hello.txt", "Hello, world!")

  """
  @spec write(Client.t(), String.t(), String.t(), binary()) :: :ok | {:error, Miosa.Error.t()}
  def write(%Client{} = client, computer_id, remote_path, content) when is_binary(content) do
    filename = Path.basename(remote_path)
    upload(client, computer_id, {:binary, content, filename}, remote_path)
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp read_upload_source({:binary, content, filename}) when is_binary(content) do
    {content, filename}
  end

  defp read_upload_source(path) when is_binary(path) do
    content = File.read!(path)
    filename = Path.basename(path)
    {content, filename}
  end

  defp to_ok({:ok, _}), do: :ok
  defp to_ok({:error, _} = err), do: err

  defp get_list(%{"data" => list}) when is_list(list), do: list
  defp get_list(%{"files" => list}) when is_list(list), do: list
  defp get_list(%{"entries" => list}) when is_list(list), do: list
  defp get_list(list) when is_list(list), do: list
  defp get_list(_), do: []
end
