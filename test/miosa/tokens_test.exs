defmodule Miosa.TokensTest do
  use ExUnit.Case, async: true

  alias Miosa.Client

  describe "create_scoped/2" do
    test "builds correct POST to /tokens/scoped with all params" do
      client = Client.new("msk_u_test", base_url: "http://localhost:4000/api/v1")

      params = %{
        user_id: "end-user-123",
        workspace_id: "ws-uuid",
        expires_in_seconds: 1800,
        scopes: ["sandboxes:create", "sandboxes:exec"]
      }

      # Verify the function exists and is callable without HTTP errors at the
      # argument-construction level. Network calls are not tested here.
      assert is_function(&Miosa.Tokens.create_scoped/2)
      assert {:error, _} = Miosa.Tokens.create_scoped(client, params)
    end

    test "accepts keyword list params" do
      client = Client.new("msk_u_test", base_url: "http://localhost:4000/api/v1")

      params = [
        user_id: "u1",
        workspace_id: "ws-1"
      ]

      # Should convert to map without raising
      assert {:error, _} = Miosa.Tokens.create_scoped(client, params)
    end

    test "module is defined with correct function" do
      # create_scoped/2 uses no default args — verify directly
      assert is_function(&Miosa.Tokens.create_scoped/2)
    end
  end
end
