defmodule Miosa.TypesTest do
  use ExUnit.Case, async: true
  alias Miosa.Types

  describe "Computer.from_map/1" do
    test "parses a full response map" do
      map = %{
        "id" => "comp_abc",
        "name" => "my-workspace",
        "status" => "running",
        "template_type" => "miosa-desktop",
        "size" => "small",
        "ip_address" => "10.0.0.1",
        "created_at" => "2026-04-01T00:00:00Z"
      }

      computer = Types.Computer.from_map(map)
      assert computer.id == "comp_abc"
      assert computer.name == "my-workspace"
      assert computer.status == :running
      assert computer.size == "small"
      assert computer.ip_address == "10.0.0.1"
    end

    test "handles unknown status gracefully" do
      map = %{"id" => "x", "name" => "x", "status" => "unknown_future_status"}
      # Should raise or use :error atom (status is from existing atom set)
      # We allow the atom conversion to fail with ArgumentError in strict mode
      # or we test our parse_status fallback
      assert_raise ArgumentError, fn ->
        Types.Computer.from_map(map)
      end
    end

    test "parses stopped status" do
      map = %{"id" => "x", "name" => "x", "status" => "stopped"}
      assert Types.Computer.from_map(map).status == :stopped
    end
  end

  describe "AgentEvent.from_sse/2" do
    test "parses thinking event with JSON data" do
      data = Jason.encode!(%{"text" => "I should open Firefox"})
      event = Types.AgentEvent.from_sse("thinking", data)
      assert event.type == :thinking
      assert event.data["text"] == "I should open Firefox"
    end

    test "parses done event" do
      event = Types.AgentEvent.from_sse("done", "{}")
      assert event.type == :done
    end

    test "parses streaming_token as :token type" do
      event = Types.AgentEvent.from_sse("streaming_token", ~s({"token": "hello"}))
      assert event.type == :token
    end

    test "parses agent_response as :result type" do
      event = Types.AgentEvent.from_sse("agent_response", ~s({"result": "done"}))
      assert event.type == :result
    end

    test "handles non-JSON data as string" do
      event = Types.AgentEvent.from_sse("thinking", "plain text")
      assert event.type == :thinking
      assert event.data == "plain text"
    end

    test "unknown event type becomes :raw" do
      event = Types.AgentEvent.from_sse("custom_event_xyz", "{}")
      assert event.type == :raw
    end
  end

  describe "ExecResult.from_map/1" do
    test "parses command result" do
      map = %{"output" => "hello\n", "exit_code" => 0, "stderr" => ""}
      result = Types.ExecResult.from_map(map)
      assert result.output == "hello\n"
      assert result.exit_code == 0
    end

    test "defaults exit_code to 0 when missing" do
      result = Types.ExecResult.from_map(%{})
      assert result.exit_code == 0
    end
  end

  describe "FileEntry.from_map/1" do
    test "parses file type" do
      entry =
        Types.FileEntry.from_map(%{
          "name" => "file.txt",
          "path" => "/home/user/file.txt",
          "type" => "file",
          "size" => 100
        })

      assert entry.type == :file
      assert entry.name == "file.txt"
    end

    test "parses directory type" do
      entry =
        Types.FileEntry.from_map(%{
          "name" => "docs",
          "path" => "/home/user/docs",
          "type" => "directory"
        })

      assert entry.type == :directory
    end

    test "parses symlink type" do
      entry =
        Types.FileEntry.from_map(%{
          "name" => "link",
          "path" => "/home/user/link",
          "type" => "symlink"
        })

      assert entry.type == :symlink
    end
  end

  describe "CreditBalance.from_map/1" do
    test "parses balance" do
      bal = Types.CreditBalance.from_map(%{"balance" => 1500, "plan" => "pro"})
      assert bal.balance == 1500
      assert bal.plan == "pro"
    end

    test "defaults balance to 0" do
      bal = Types.CreditBalance.from_map(%{})
      assert bal.balance == 0
    end
  end

  describe "AgentSession.from_map/1" do
    test "parses all statuses" do
      for status <- ~w(pending running completed failed cancelled) do
        map = %{"id" => "s1", "computer_id" => "c1", "status" => status}
        session = Types.AgentSession.from_map(map)
        assert session.status == String.to_atom(status)
      end
    end

    test "unknown status defaults to :pending" do
      map = %{"id" => "s1", "computer_id" => "c1", "status" => "??"}
      assert Types.AgentSession.from_map(map).status == :pending
    end
  end
end
