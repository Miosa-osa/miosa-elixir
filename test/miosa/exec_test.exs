defmodule Miosa.ExecTest do
  use ExUnit.Case, async: true
  alias Miosa.{Error, Exec, Types}

  setup do
    bypass = Bypass.open()
    client = Miosa.client("msk_u_test", base_url: "http://localhost:#{bypass.port}/api/v1")
    {:ok, bypass: bypass, client: client, cid: "comp_abc"}
  end

  describe "bash/4" do
    test "returns ExecResult on success", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "POST", "/api/v1/computers/comp_abc/exec", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded["command"] == "ls -la"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{
            "output" => "total 0\ndrwxr-xr-x 2 user user 60\n",
            "exit_code" => 0
          })
        )
      end)

      assert {:ok, result} = Exec.bash(client, cid, "ls -la")
      assert result.output == "total 0\ndrwxr-xr-x 2 user user 60\n"
      assert result.exit_code == 0
    end

    test "returns ExecResult with non-zero exit code", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "POST", "/api/v1/computers/comp_abc/exec", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{
            "output" => "",
            "stderr" => "command not found: foobar",
            "exit_code" => 127
          })
        )
      end)

      assert {:ok, result} = Exec.bash(client, cid, "foobar")
      assert result.exit_code == 127
      assert result.stderr == "command not found: foobar"
    end

    test "passes optional working_dir", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "POST", "/api/v1/computers/comp_abc/exec", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded["working_dir"] == "/tmp"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"output" => "", "exit_code" => 0}))
      end)

      assert {:ok, _} = Exec.bash(client, cid, "pwd", working_dir: "/tmp")
    end

    test "returns error on API failure", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "POST", "/api/v1/computers/comp_abc/exec", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          409,
          Jason.encode!(%{"error" => "Not running", "code" => "NOT_RUNNING"})
        )
      end)

      assert {:error, %Error{status: 409}} = Exec.bash(client, cid, "ls")
    end
  end

  describe "python/4" do
    test "posts to /exec/python endpoint", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "POST", "/api/v1/computers/comp_abc/exec/python", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert String.contains?(decoded["code"], "print")

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"output" => "hello\n", "exit_code" => 0}))
      end)

      assert {:ok, result} = Exec.python(client, cid, "print('hello')")
      assert result.output == "hello\n"
    end
  end

  describe "bash!/4" do
    test "returns ExecResult directly on success", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "POST", "/api/v1/computers/comp_abc/exec", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"output" => "ok", "exit_code" => 0}))
      end)

      result = Exec.bash!(client, cid, "echo ok")
      assert %Types.ExecResult{} = result
      assert result.output == "ok"
    end

    test "raises Miosa.Error on API failure", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "POST", "/api/v1/computers/comp_abc/exec", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(500, Jason.encode!(%{"error" => "Internal error"}))
      end)

      assert_raise Miosa.Error, fn ->
        Exec.bash!(client, cid, "ls")
      end
    end
  end
end
