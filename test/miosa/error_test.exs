defmodule Miosa.ErrorTest do
  use ExUnit.Case, async: true
  alias Miosa.Error

  describe "message/1" do
    test "formats without status" do
      err = %Error{message: "network failure", status: nil, code: nil}
      assert Exception.message(err) == "network failure"
    end

    test "formats with status and no code" do
      err = %Error{message: "not found", status: 404, code: nil}
      assert Exception.message(err) == "[404] not found"
    end

    test "formats with status and code" do
      err = %Error{message: "not found", status: 404, code: "NOT_FOUND"}
      assert Exception.message(err) == "[404] NOT_FOUND: not found"
    end
  end

  describe "from_response/1" do
    test "extracts error and code from API envelope" do
      response = %Req.Response{
        status: 404,
        body: %{"error" => "Resource not found", "code" => "NOT_FOUND"}
      }

      err = Error.from_response(response)
      assert err.message == "Resource not found"
      assert err.code == "NOT_FOUND"
      assert err.status == 404
    end

    test "extracts error without code" do
      response = %Req.Response{status: 500, body: %{"error" => "Internal error"}}
      err = Error.from_response(response)
      assert err.message == "Internal error"
      assert err.code == nil
    end

    test "extracts message key as fallback" do
      response = %Req.Response{
        status: 422,
        body: %{"message" => "Invalid params", "code" => "INVALID"}
      }

      err = Error.from_response(response)
      assert err.message == "Invalid params"
      assert err.code == "INVALID"
    end

    test "handles unexpected body" do
      response = %Req.Response{status: 503, body: "Service Unavailable"}
      err = Error.from_response(response)
      assert err.message == "Unexpected API error"
      assert err.status == 503
    end
  end

  describe "from_exception/1" do
    test "wraps a RuntimeError" do
      exception = %RuntimeError{message: "connection refused"}
      err = Error.from_exception(exception)
      assert err.message == "connection refused"
      assert err.status == nil
      assert err.code == nil
    end
  end

  describe "raise/1" do
    test "is a valid exception" do
      assert_raise Error, "[402] INSUFFICIENT_CREDITS: not enough credits", fn ->
        raise Error, message: "not enough credits", status: 402, code: "INSUFFICIENT_CREDITS"
      end
    end
  end
end
