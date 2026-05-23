defmodule Miosa.CheckpointsTest do
  use ExUnit.Case, async: true

  alias Miosa.{Checkpoints, Error}

  setup do
    bypass = Bypass.open()
    client = Miosa.client("msk_u_test", base_url: "http://localhost:#{bypass.port}/api/v1")
    {:ok, bypass: bypass, client: client, cid: "comp_abc"}
  end

  describe "create/3" do
    test "returns a Snapshot struct on 201", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "POST", "/api/v1/computers/comp_abc/checkpoints", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          201,
          Jason.encode!(%{
            "id" => "snap_xyz",
            "computer_id" => cid,
            "name" => "before-deploy",
            "status" => "ready",
            "size_bytes" => 1_073_741_824,
            "created_at" => "2026-01-01T00:00:00Z"
          })
        )
      end)

      assert {:ok, snap} = Checkpoints.create(client, cid, %{name: "before-deploy"})
      assert snap.id == "snap_xyz"
      assert snap.status == :ready
      assert snap.size_bytes == 1_073_741_824
    end

    test "accepts empty params", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "POST", "/api/v1/computers/comp_abc/checkpoints", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          201,
          Jason.encode!(%{"id" => "snap_1", "computer_id" => cid, "status" => "creating"})
        )
      end)

      assert {:ok, snap} = Checkpoints.create(client, cid)
      assert snap.status == :creating
    end

    test "returns error when computer not found", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "POST", "/api/v1/computers/comp_abc/checkpoints", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          404,
          Jason.encode!(%{"error" => "Not found", "code" => "NOT_FOUND"})
        )
      end)

      assert {:error, %Error{status: 404}} = Checkpoints.create(client, cid, %{})
    end
  end

  describe "list/2" do
    test "returns list of snapshots", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "GET", "/api/v1/computers/comp_abc/checkpoints", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(
          200,
          Jason.encode!([
            %{"id" => "s1", "computer_id" => cid, "status" => "ready"},
            %{"id" => "s2", "computer_id" => cid, "status" => "ready"}
          ])
        )
      end)

      assert {:ok, snaps} = Checkpoints.list(client, cid)
      assert length(snaps) == 2
    end

    test "returns empty list when none exist", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(bypass, "GET", "/api/v1/computers/comp_abc/checkpoints", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!([]))
      end)

      assert {:ok, []} = Checkpoints.list(client, cid)
    end
  end

  describe "get/3" do
    test "fetches a snapshot by id", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(
        bypass,
        "GET",
        "/api/v1/computers/comp_abc/checkpoints/snap_xyz",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.send_resp(
            200,
            Jason.encode!(%{"id" => "snap_xyz", "computer_id" => cid, "status" => "ready"})
          )
        end
      )

      assert {:ok, snap} = Checkpoints.get(client, cid, "snap_xyz")
      assert snap.id == "snap_xyz"
    end
  end

  describe "delete/3" do
    test "returns :ok on success", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(
        bypass,
        "DELETE",
        "/api/v1/computers/comp_abc/checkpoints/snap_del",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.send_resp(200, Jason.encode!(%{"ok" => true}))
        end
      )

      assert :ok = Checkpoints.delete(client, cid, "snap_del")
    end
  end

  describe "restore/3" do
    test "returns :ok when restore is accepted", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(
        bypass,
        "POST",
        "/api/v1/computers/comp_abc/checkpoints/snap_xyz/restore",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.send_resp(202, Jason.encode!(%{"ok" => true}))
        end
      )

      assert :ok = Checkpoints.restore(client, cid, "snap_xyz")
    end

    test "returns error on 409 conflict", %{bypass: bypass, client: client, cid: cid} do
      Bypass.expect_once(
        bypass,
        "POST",
        "/api/v1/computers/comp_abc/checkpoints/snap_xyz/restore",
        fn conn ->
          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.send_resp(
            409,
            Jason.encode!(%{"error" => "Computer is running", "code" => "CONFLICT"})
          )
        end
      )

      assert {:error, %Error{status: 409}} = Checkpoints.restore(client, cid, "snap_xyz")
    end
  end
end
