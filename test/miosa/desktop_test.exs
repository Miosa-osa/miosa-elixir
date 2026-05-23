defmodule Miosa.DesktopTest do
  use ExUnit.Case, async: true
  alias Miosa.{Desktop, Error}

  setup do
    bypass = Bypass.open()
    client = Miosa.client("msk_u_test", base_url: "http://localhost:#{bypass.port}/api/v1")
    {:ok, bypass: bypass, client: client, cid: "comp_abc"}
  end

  describe "screenshot/2" do
    test "returns PNG bytes on success", %{bypass: bypass, client: client, cid: cid} do
      fake_png = <<137, 80, 78, 71, 13, 10, 26, 10>>

      Bypass.expect_once(
        bypass,
        "GET",
        "/api/v1/computers/comp_abc/desktop/screenshot",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_content_type("image/png")
          |> Plug.Conn.send_resp(200, fake_png)
        end
      )

      assert {:ok, ^fake_png} = Desktop.screenshot(client, cid)
    end
  end

  describe "click/4" do
    test "sends click action and returns :ok", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "POST", "/api/v1/computers/comp_abc/desktop/click", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded["x"] == 100
        assert decoded["y"] == 200

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true}))
      end)

      assert :ok = Desktop.click(client, cid, 100, 200)
    end
  end

  describe "type/3" do
    test "sends type action with text", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "POST", "/api/v1/computers/comp_abc/desktop/type", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded["text"] == "Hello, world!"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true}))
      end)

      assert :ok = Desktop.type(client, cid, "Hello, world!")
    end
  end

  describe "key/3" do
    test "sends key action with combo string", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "POST", "/api/v1/computers/comp_abc/desktop/key", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded["key"] == "ctrl+c"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true}))
      end)

      assert :ok = Desktop.key(client, cid, "ctrl+c")
    end
  end

  describe "scroll/6" do
    test "sends scroll action with direction and amount", %{
      bypass: bypass,
      client: client,
      cid: cid
    } do
      Bypass.expect_once(bypass, "POST", "/api/v1/computers/comp_abc/desktop/scroll", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded["direction"] == "down"
        assert decoded["amount"] == 3

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true}))
      end)

      assert :ok = Desktop.scroll(client, cid, 500, 300)
    end
  end

  describe "drag/6" do
    test "sends drag action with from/to coordinates", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "POST", "/api/v1/computers/comp_abc/desktop/drag", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded["from_x"] == 10
        assert decoded["from_y"] == 20
        assert decoded["to_x"] == 300
        assert decoded["to_y"] == 400

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true}))
      end)

      assert :ok = Desktop.drag(client, cid, 10, 20, 300, 400)
    end
  end

  describe "windows/2" do
    test "returns list of Window structs", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "GET", "/api/v1/computers/comp_abc/desktop/windows", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!([
            %{
              "id" => 1,
              "title" => "Firefox",
              "x" => 0,
              "y" => 0,
              "width" => 1920,
              "height" => 1080
            }
          ])
        )
      end)

      assert {:ok, [window]} = Desktop.windows(client, cid)
      assert window.title == "Firefox"
      assert window.id == 1
    end
  end

  describe "cursor/2" do
    test "returns CursorPosition struct", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "GET", "/api/v1/computers/comp_abc/desktop/cursor", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"x" => 640, "y" => 480}))
      end)

      assert {:ok, pos} = Desktop.cursor(client, cid)
      assert pos.x == 640
      assert pos.y == 480
    end
  end

  describe "launch/3" do
    test "sends launch action", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "POST", "/api/v1/computers/comp_abc/desktop/launch", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        assert Jason.decode!(body)["app"] == "firefox"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true}))
      end)

      assert :ok = Desktop.launch(client, cid, "firefox")
    end
  end

  describe "error handling" do
    test "returns error when computer not running", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(
        bypass,
        "GET",
        "/api/v1/computers/comp_abc/desktop/screenshot",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.send_resp(
            409,
            Jason.encode!(%{"error" => "Computer not running", "code" => "NOT_RUNNING"})
          )
        end
      )

      assert {:error, %Error{status: 409, code: "NOT_RUNNING"}} = Desktop.screenshot(client, cid)
    end
  end
end
