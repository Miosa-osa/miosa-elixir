defmodule Miosa.ClientTest do
  use ExUnit.Case, async: true
  alias Miosa.Client

  describe "new/2" do
    test "creates a client with valid key" do
      client = Client.new("msk_u_abc123")
      assert client.api_key == "msk_u_abc123"
      assert client.base_url == "https://api.miosa.ai/api/v1"
      assert client.timeout == 30_000
    end

    test "accepts admin-scoped key" do
      client = Client.new("msk_a_adminkey")
      assert client.api_key == "msk_a_adminkey"
    end

    test "raises on invalid key prefix" do
      assert_raise ArgumentError, ~r/msk_/, fn ->
        Client.new("sk_invalid_key")
      end
    end

    test "accepts custom base_url" do
      client = Client.new("msk_u_abc", base_url: "http://localhost:4000/api/v1")
      assert client.base_url == "http://localhost:4000/api/v1"
    end

    test "accepts custom timeout" do
      client = Client.new("msk_u_abc", timeout: 5_000)
      assert client.timeout == 5_000
    end
  end

  describe "Miosa.client/2" do
    test "delegates to Client.new/2" do
      client = Miosa.client("msk_u_abc123")
      assert %Client{} = client
      assert client.api_key == "msk_u_abc123"
    end
  end
end
