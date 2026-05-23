# `Miosa.Desktop`
[🔗](https://github.com/Miosa-osa/miosa-elixir/blob/v1.0.2/lib/miosa/desktop.ex#L1)

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

# `click`

```elixir
@spec click(Miosa.Client.t(), String.t(), integer(), integer()) ::
  :ok | {:error, Miosa.Error.t()}
```

Left-clicks at the given `(x, y)` desktop coordinates.

# `cursor`

```elixir
@spec cursor(Miosa.Client.t(), String.t()) ::
  Miosa.Client.result(Miosa.Types.CursorPosition.t())
```

Returns the current mouse cursor position on the desktop.

# `double_click`

```elixir
@spec double_click(Miosa.Client.t(), String.t(), integer(), integer()) ::
  :ok | {:error, Miosa.Error.t()}
```

Double-clicks at the given `(x, y)` desktop coordinates.

# `drag`

```elixir
@spec drag(Miosa.Client.t(), String.t(), integer(), integer(), integer(), integer()) ::
  :ok | {:error, Miosa.Error.t()}
```

Click-drags from `(from_x, from_y)` to `(to_x, to_y)`.

Useful for selecting text, resizing windows, or drag-and-drop operations.

# `focus_window`

```elixir
@spec focus_window(Miosa.Client.t(), String.t(), integer()) ::
  :ok | {:error, Miosa.Error.t()}
```

Brings a window to the foreground by its window ID.

Use `windows/2` to list window IDs.

# `key`

```elixir
@spec key(Miosa.Client.t(), String.t(), String.t()) :: :ok | {:error, Miosa.Error.t()}
```

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

# `launch`

```elixir
@spec launch(Miosa.Client.t(), String.t(), String.t()) ::
  :ok | {:error, Miosa.Error.t()}
```

Launches an application by name or command.

Examples:
- `"firefox"`
- `"code"` (VS Code)
- `"xterm"`
- `"nautilus /home/user"`

# `move`

```elixir
@spec move(Miosa.Client.t(), String.t(), integer(), integer()) ::
  :ok | {:error, Miosa.Error.t()}
```

Moves the mouse cursor to `(x, y)` without clicking.

# `right_click`

```elixir
@spec right_click(Miosa.Client.t(), String.t(), integer(), integer()) ::
  :ok | {:error, Miosa.Error.t()}
```

Right-clicks at the given `(x, y)` desktop coordinates.

# `screenshot`

```elixir
@spec screenshot(Miosa.Client.t(), String.t()) :: Miosa.Client.result(binary())
```

Captures a screenshot of the computer desktop.

Returns raw PNG bytes. Save with `File.write!/2` or encode as base64
with `Base.encode64/1`.

# `scroll`

```elixir
@spec scroll(
  Miosa.Client.t(),
  String.t(),
  integer(),
  integer(),
  String.t(),
  integer()
) ::
  :ok | {:error, Miosa.Error.t()}
```

Scrolls the mouse wheel at the given `(x, y)` coordinates.

`direction` is `"up"` or `"down"`. `amount` is the number of scroll clicks
(default `3`).

# `type`

```elixir
@spec type(Miosa.Client.t(), String.t(), String.t()) ::
  :ok | {:error, Miosa.Error.t()}
```

Types the given text string at the current cursor position.

Special characters and Unicode are supported. For keyboard shortcuts
(Ctrl, Alt, etc.), use `key/3` instead.

# `wait`

```elixir
@spec wait(Miosa.Client.t(), String.t(), pos_integer()) ::
  :ok | {:error, Miosa.Error.t()}
```

Waits (sleeps) for `ms` milliseconds inside the VM.

Useful when scripting sequences that need a pause after an action
(e.g. waiting for an animation or page load). Prefer agent sessions
for intelligent waiting.

# `windows`

```elixir
@spec windows(Miosa.Client.t(), String.t()) ::
  Miosa.Client.result([Miosa.Types.Window.t()])
```

Lists all open windows on the desktop.

Returns a list of `Miosa.Types.Window` structs with position and size.

---

*Consult [api-reference.md](api-reference.md) for complete listing*
