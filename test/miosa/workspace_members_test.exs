defmodule Miosa.WorkspaceMembersTest do
  use ExUnit.Case, async: true

  alias Miosa.WorkspaceMembers

  setup do
    bypass = Bypass.open()
    client = Miosa.client("msk_u_test", base_url: "http://localhost:#{bypass.port}/api/v1")
    {:ok, bypass: bypass, client: client}
  end

  defp member_json(user_id \\ "usr_abc", role \\ "member") do
    %{
      "user_id" => user_id,
      "email" => "#{user_id}@example.com",
      "name" => "Test User",
      "avatar_url" => nil,
      "role" => role,
      "joined_at" => "2026-05-01T10:00:00Z",
      "added_by" => nil
    }
  end

  defp member_record_json(user_id \\ "usr_def", role \\ "member") do
    %{
      "user_id" => user_id,
      "workspace_id" => "ws-uuid",
      "role" => role,
      "joined_at" => "2026-05-22T09:00:00Z",
      "added_by" => "usr_abc"
    }
  end

  describe "list/2" do
    test "returns list of members on 200", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/workspaces/ws-uuid/members", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!(%{"data" => [member_json("usr_alice", "owner"), member_json("usr_bob", "member")]})
        )
      end)

      assert {:ok, members} = WorkspaceMembers.list(client, "ws-uuid")
      assert length(members) == 2
      assert hd(members)["user_id"] == "usr_alice"
      assert hd(members)["role"] == "owner"
    end

    test "returns empty list when workspace has no members", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "GET", "/api/v1/workspaces/ws-uuid/members", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"data" => []}))
      end)

      assert {:ok, []} = WorkspaceMembers.list(client, "ws-uuid")
    end
  end

  describe "add/4" do
    test "posts user_id and role, returns member record", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/workspaces/ws-uuid/members", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded["user_id"] == "usr_def"
        assert decoded["role"] == "member"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(201, Jason.encode!(%{"data" => member_record_json()}))
      end)

      assert {:ok, record} = WorkspaceMembers.add(client, "ws-uuid", "usr_def", "member")
      assert record["user_id"] == "usr_def"
      assert record["role"] == "member"
    end

    test "returns error when user is not a tenant member", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "POST", "/api/v1/workspaces/ws-uuid/members", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          422,
          Jason.encode!(%{"error" => %{"code" => "NOT_TENANT_MEMBER", "message" => "User is not a tenant member"}})
        )
      end)

      assert {:error, _} = WorkspaceMembers.add(client, "ws-uuid", "usr_outsider", "member")
    end
  end

  describe "update_role/4" do
    test "patches the member role and returns updated record", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "PATCH", "/api/v1/workspaces/ws-uuid/members/usr_def", fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded["role"] == "admin"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"data" => member_record_json("usr_def", "admin")}))
      end)

      assert {:ok, record} = WorkspaceMembers.update_role(client, "ws-uuid", "usr_def", "admin")
      assert record["role"] == "admin"
    end
  end

  describe "remove/3" do
    test "sends DELETE and returns ok", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "DELETE", "/api/v1/workspaces/ws-uuid/members/usr_def", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"deleted" => true}))
      end)

      assert {:ok, %{"deleted" => true}} = WorkspaceMembers.remove(client, "ws-uuid", "usr_def")
    end

    test "returns error on LAST_OWNER conflict", %{bypass: bypass, client: client} do
      Bypass.expect_once(bypass, "DELETE", "/api/v1/workspaces/ws-uuid/members/usr_owner", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          409,
          Jason.encode!(%{"error" => %{"code" => "LAST_OWNER", "message" => "Cannot remove the last workspace owner"}})
        )
      end)

      assert {:error, _} = WorkspaceMembers.remove(client, "ws-uuid", "usr_owner")
    end
  end
end
