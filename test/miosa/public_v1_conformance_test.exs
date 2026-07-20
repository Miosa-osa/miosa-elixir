defmodule Miosa.PublicV1ConformanceTest do
  use ExUnit.Case, async: true

  @expected_contract_version "1.0.0"
  @expected_contract_commit "774abcbc97380b599009759632691dc60d8e6b38"

  setup do
    bypass = Bypass.open()
    client = Miosa.client("msk_u_test", base_url: "http://localhost:#{bypass.port}/api/v1")
    {:ok, bypass: bypass, client: client}
  end

  test "sends the canonical default-small create fixture", %{bypass: bypass, client: client} do
    create = fixture("create-default-small-request")
    sandbox = fixture("sandbox-response")
    parent = self()

    Bypass.expect_once(bypass, "POST", "/api/v1/sandboxes", fn conn ->
      {:ok, request_body, conn} = Plug.Conn.read_body(conn)
      send(parent, {:request_body, Jason.decode!(request_body)})

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(201, Jason.encode!(sandbox["body"]))
    end)

    assert {:ok, _} = Miosa.Sandboxes.create(client, create["body"])
    assert_receive {:request_body, body}
    assert body == create["body"]
  end

  test "decodes canonical sandbox, pause, usage, and template fixtures", %{
    bypass: bypass,
    client: client
  } do
    sandbox = fixture("sandbox-response")
    pause = fixture("pause-response")
    usage = fixture("usage-response")
    templates = fixture("templates-response")
    id = sandbox["body"]["id"]

    responses = %{
      {"GET", "/api/v1/sandboxes/#{id}"} => sandbox["body"],
      {"POST", "/api/v1/sandboxes/#{id}/pause"} => pause["body"],
      {"GET", "/api/v1/sandboxes/#{id}/usage"} => usage["body"],
      {"GET", "/api/v1/templates"} => templates["body"]
    }

    Bypass.expect(bypass, fn conn ->
      body = Map.fetch!(responses, {conn.method, conn.request_path})

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(200, Jason.encode!(body))
    end)

    assert {:ok, decoded} = Miosa.Sandboxes.get(client, id)
    assert decoded["resource_contract"]["id"] == "sandbox/small@v1"
    assert decoded["timeout_remaining_ms"] == 3_599_000
    assert {:ok, %{"state" => "paused"}} = Miosa.Sandboxes.pause(client, id)
    assert {:ok, measured} = Miosa.Sandboxes.usage(client, id)
    assert measured["provisioned_vcpu_ms"] == 94_000
    assert {:ok, [template]} = Miosa.Templates.list(client, product: "sandbox")
    assert template["default_size"] == "small"
  end

  defp fixture(name) do
    root = contracts_root!()
    path = Path.join([root, "fixtures", "conformance", "#{name}.yaml"])

    try do
      path
      |> String.to_charlist()
      |> :yamerl_constr.file()
      |> hd()
      |> normalize_yaml()
    rescue
      error ->
        message =
          "Cannot load conformance fixture #{path}; resolved root=#{root}; " <>
            "expected public-v1 version=#{@expected_contract_version}; " <>
            "expected commit=#{@expected_contract_commit}: #{Exception.message(error)}"

        reraise RuntimeError, [message: message], __STACKTRACE__
    catch
      kind, reason ->
        message =
          "Cannot load conformance fixture #{path}; resolved root=#{root}; " <>
            "expected public-v1 version=#{@expected_contract_version}; " <>
            "expected commit=#{@expected_contract_commit}: #{inspect({kind, reason})}"

        :erlang.raise(:error, RuntimeError.exception(message), __STACKTRACE__)
    end
  end

  defp contracts_root! do
    root =
      case System.get_env("MIOSA_API_CONTRACTS_ROOT") do
        nil -> Path.expand("../contract-fixtures/public-v1", File.cwd!())
        configured -> Path.expand(configured)
      end

    try do
      actual_version =
        if System.get_env("MIOSA_API_CONTRACTS_ROOT") do
          root
          |> Path.join("openapi/public-v1.yaml")
          |> String.to_charlist()
          |> :yamerl_constr.file()
          |> hd()
          |> normalize_yaml()
          |> get_in(["info", "version"])
        else
          actual_commit = root |> Path.join("CONTRACT_COMMIT") |> File.read!() |> String.trim()

          if actual_commit != @expected_contract_commit do
            raise "found contract commit #{actual_commit}"
          end

          root |> Path.join("CONTRACT_VERSION") |> File.read!() |> String.trim()
        end

      if actual_version != @expected_contract_version do
        raise "found OpenAPI version #{inspect(actual_version)}"
      end
    rescue
      error ->
        message =
          "MIOSA API contracts unavailable or incompatible: resolved root=#{root}; " <>
            "expected public-v1 version=#{@expected_contract_version}; " <>
            "expected commit=#{@expected_contract_commit}: #{Exception.message(error)}"

        reraise RuntimeError, [message: message], __STACKTRACE__
    catch
      kind, reason ->
        message =
          "MIOSA API contracts unavailable or incompatible: resolved root=#{root}; " <>
            "expected public-v1 version=#{@expected_contract_version}; " <>
            "expected commit=#{@expected_contract_commit}: #{inspect({kind, reason})}"

        :erlang.raise(:error, RuntimeError.exception(message), __STACKTRACE__)
    end

    root
  end

  defp normalize_yaml(value) when is_list(value) do
    cond do
      match?([{_, _} | _], value) ->
        Map.new(value, fn {key, item} -> {to_string(key), normalize_yaml(item)} end)

      List.ascii_printable?(value) ->
        to_string(value)

      true ->
        Enum.map(value, &normalize_yaml/1)
    end
  end

  defp normalize_yaml(value), do: value
end
