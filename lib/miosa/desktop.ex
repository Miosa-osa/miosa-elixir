defmodule Miosa.Desktop do
  @moduledoc """
  Control the desktop environment of a running MIOSA computer.

  All actions interact with the live X11 desktop inside the VM via the
  MIOSA API. The computer must be in `:running` status.

  ## Input Actions
  - `screenshot/2` — Capture the current desktop as PNG bytes
  - `click/4` — Left-click at coordinates
  - `double_click/4` — Double-click at coordinates
  - `right_click/4` — Right-click at coordinates
  - `drag/6` — Click-drag from one point to another
  - `type/3` — Type a string of text
  - `key/3` — Press a keyboard shortcut (e.g. `"ctrl+c"`, `"Return"`)
  - `scroll/5` — Scroll the mouse wheel at coordinates
  - `wait/3` — Sleep inside the VM for N milliseconds

  ## Window Management
  - `windows/2` — List open windows
  - `cursor/2` — Get current cursor position
  - `focus_window/3` — Bring a window to the foreground by ID
  - `launch/3` — Launch an application by name

  ## Example

      {:ok, png} = Miosa.Desktop.screenshot(client, computer_id)
      File.write!("screen.png", png)

      :ok = Miosa.Desktop.click(client, computer_id, 500, 300)
      :ok = Miosa.Desktop.type(client, computer_id, "Hello, world!")
      :ok = Miosa.Desktop.key(client, computer_id, "Return")
      :ok = Miosa.Desktop.key(client, computer_id, "ctrl+c")

  """

  alias Miosa.{Client, Types}

  @doc """
  Captures a screenshot of the computer desktop.

  Returns raw PNG bytes. Save with `File.write!/2` or encode as base64
  with `Base.encode64/1`.
  """
  @spec screenshot(Client.t(), String.t()) :: Client.result(binary())
  def screenshot(%Client{} = client, computer_id) when is_binary(computer_id) do
    Client.get_binary(client, "/computers/#{computer_id}/desktop/screenshot")
  end

  @doc """
  Left-clicks at the given `(x, y)` desktop coordinates.
  """
  @spec click(Client.t(), String.t(), integer(), integer()) :: :ok | {:error, Miosa.Error.t()}
  def click(%Client{} = client, computer_id, x, y) when is_integer(x) and is_integer(y) do
    post_action(client, computer_id, "click", %{x: x, y: y})
  end

  @doc """
  Double-clicks at the given `(x, y)` desktop coordinates.
  """
  @spec double_click(Client.t(), String.t(), integer(), integer()) ::
          :ok | {:error, Miosa.Error.t()}
  def double_click(%Client{} = client, computer_id, x, y) when is_integer(x) and is_integer(y) do
    post_action(client, computer_id, "double-click", %{x: x, y: y})
  end

  @doc """
  Right-clicks at the given `(x, y)` desktop coordinates.
  """
  @spec right_click(Client.t(), String.t(), integer(), integer()) ::
          :ok | {:error, Miosa.Error.t()}
  def right_click(%Client{} = client, computer_id, x, y) when is_integer(x) and is_integer(y) do
    post_action(client, computer_id, "right-click", %{x: x, y: y})
  end

  @doc """
  Click-drags from `(from_x, from_y)` to `(to_x, to_y)`.

  Useful for selecting text, resizing windows, or drag-and-drop operations.
  """
  @spec drag(Client.t(), String.t(), integer(), integer(), integer(), integer()) ::
          :ok | {:error, Miosa.Error.t()}
  def drag(%Client{} = client, computer_id, from_x, from_y, to_x, to_y)
      when is_integer(from_x) and is_integer(from_y) and is_integer(to_x) and is_integer(to_y) do
    post_action(client, computer_id, "drag", %{
      from_x: from_x,
      from_y: from_y,
      to_x: to_x,
      to_y: to_y
    })
  end

  @doc """
  Types the given text string at the current cursor position.

  Special characters and Unicode are supported. For keyboard shortcuts
  (Ctrl, Alt, etc.), use `key/3` instead.
  """
  @spec type(Client.t(), String.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def type(%Client{} = client, computer_id, text) when is_binary(text) do
    post_action(client, computer_id, "type", %{text: text})
  end

  @doc """
  Presses a keyboard key or shortcut combination.

  Uses X11 keysym notation. Common examples:
  - `"Return"` — Enter key
  - `"Escape"` — Escape key
  - `"ctrl+c"` — Copy
  - `"ctrl+v"` — Paste
  - `"ctrl+a"` — Select all
  - `"alt+F4"` — Close window
  - `"super"` — Windows/Super key
  - `"Tab"` — Tab key
  - `"BackSpace"` — Backspace

  """
  @spec key(Client.t(), String.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def key(%Client{} = client, computer_id, key_combo) when is_binary(key_combo) do
    post_action(client, computer_id, "key", %{key: key_combo})
  end

  @doc """
  Scrolls the mouse wheel at the given `(x, y)` coordinates.

  `direction` is `"up"` or `"down"`. `amount` is the number of scroll clicks
  (default `3`).
  """
  @spec scroll(Client.t(), String.t(), integer(), integer(), String.t(), integer()) ::
          :ok | {:error, Miosa.Error.t()}
  def scroll(%Client{} = client, computer_id, x, y, direction \\ "down", amount \\ 3)
      when is_integer(x) and is_integer(y) and direction in ["up", "down"] do
    post_action(client, computer_id, "scroll", %{x: x, y: y, direction: direction, amount: amount})
  end

  @doc """
  Waits (sleeps) for `ms` milliseconds inside the VM.

  Useful when scripting sequences that need a pause after an action
  (e.g. waiting for an animation or page load). Prefer agent sessions
  for intelligent waiting.
  """
  @spec wait(Client.t(), String.t(), pos_integer()) :: :ok | {:error, Miosa.Error.t()}
  def wait(%Client{} = client, computer_id, ms) when is_integer(ms) and ms > 0 do
    post_action(client, computer_id, "wait", %{ms: ms})
  end

  @doc """
  Moves the mouse cursor to `(x, y)` without clicking.
  """
  @spec move(Client.t(), String.t(), integer(), integer()) :: :ok | {:error, Miosa.Error.t()}
  def move(%Client{} = client, computer_id, x, y) when is_integer(x) and is_integer(y) do
    post_action(client, computer_id, "move", %{x: x, y: y})
  end

  @doc """
  Lists all open windows on the desktop.

  Returns a list of `Miosa.Types.Window` structs with position and size.
  """
  @spec windows(Client.t(), String.t()) :: Client.result([Types.Window.t()])
  def windows(%Client{} = client, computer_id) when is_binary(computer_id) do
    case Client.get(client, "/computers/#{computer_id}/desktop/windows") do
      {:ok, body} ->
        wins =
          body
          |> get_list()
          |> Enum.map(&Types.Window.from_map/1)

        {:ok, wins}

      {:error, _} = err ->
        err
    end
  end

  @doc """
  Returns the current mouse cursor position on the desktop.
  """
  @spec cursor(Client.t(), String.t()) :: Client.result(Types.CursorPosition.t())
  def cursor(%Client{} = client, computer_id) when is_binary(computer_id) do
    case Client.get(client, "/computers/#{computer_id}/desktop/cursor") do
      {:ok, body} -> {:ok, Types.CursorPosition.from_map(body)}
      {:error, _} = err -> err
    end
  end

  @doc """
  Brings a window to the foreground by its window ID.

  Use `windows/2` to list window IDs.
  """
  @spec focus_window(Client.t(), String.t(), integer()) :: :ok | {:error, Miosa.Error.t()}
  def focus_window(%Client{} = client, computer_id, window_id) when is_integer(window_id) do
    post_action(client, computer_id, "window/focus", %{window_id: window_id})
  end

  @doc """
  Launches an application by name or command.

  Examples:
  - `"firefox"`
  - `"code"` (VS Code)
  - `"xterm"`
  - `"nautilus /home/user"`

  """
  @spec launch(Client.t(), String.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
  def launch(%Client{} = client, computer_id, app_name) when is_binary(app_name) do
    post_action(client, computer_id, "launch", %{app: app_name})
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp post_action(client, computer_id, action, body) do
    client
    |> Client.post("/computers/#{computer_id}/desktop/#{action}", body)
    |> to_ok()
  end

  defp to_ok({:ok, _}), do: :ok
  defp to_ok({:error, _} = err), do: err

  defp get_list(%{"data" => list}) when is_list(list), do: list
  defp get_list(%{"windows" => list}) when is_list(list), do: list
  defp get_list(list) when is_list(list), do: list
  defp get_list(_), do: []
end
