defmodule Miosa.TransportTest do
  @moduledoc """
  Transport-layer tests: verify the shared Finch pool is started once and
  reused across every `Miosa.Client.new/2` call. Connection pooling
  (and TLS session resumption inside Mint) is what eliminates the
  per-call handshake tax.
  """

  use ExUnit.Case, async: false
  alias Miosa.Client

  @finch_pool :miosa_finch_pool

  describe "Finch pool lifecycle" do
    test "ensure_finch_pool_started/0 is idempotent" do
      assert :ok = Client.ensure_finch_pool_started()
      pid1 = Process.whereis(@finch_pool)
      assert is_pid(pid1)

      assert :ok = Client.ensure_finch_pool_started()
      pid2 = Process.whereis(@finch_pool)
      assert pid2 == pid1, "Finch pool must be reused across calls, not restarted"
    end

    test "Client.new/2 wires the shared finch pool into the Req struct" do
      client = Client.new("msk_u_abc123")
      # The Req.Request struct stores its options as a map under :options.
      opts = client._req.options

      assert Map.get(opts, :finch) == @finch_pool,
             "Client.new must point Req at the shared Finch pool"
    end

    test "two clients share the same Finch pool process" do
      _c1 = Client.new("msk_u_abc")
      pid_a = Process.whereis(@finch_pool)

      _c2 = Client.new("msk_a_admin")
      pid_b = Process.whereis(@finch_pool)

      assert pid_a == pid_b
    end
  end
end
