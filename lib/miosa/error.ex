defmodule Miosa.Error do
  @moduledoc """
  Exception raised for MIOSA API errors.

  Covers both HTTP-level errors (4xx, 5xx) and client-level errors
  (network failures, JSON decode errors, invalid configuration).

  ## Fields

    * `:message` — Human-readable error description.
    * `:status` — HTTP status code (integer), or `nil` for non-HTTP errors.
    * `:code` — Machine-readable error code string from the API (e.g. `"INSUFFICIENT_CREDITS"`), or `nil`.
    * `:body` — Raw response body map, when available.

  ## Examples

      iex> raise Miosa.Error, message: "Not found", status: 404, code: "NOT_FOUND"
      ** (Miosa.Error) [404] NOT_FOUND: Not found

  """

  defexception [:message, :status, :code, :body]

  @type t :: %__MODULE__{
          message: String.t(),
          status: pos_integer() | nil,
          code: String.t() | nil,
          body: map() | nil
        }

  @impl true
  def message(%__MODULE__{status: nil, message: msg}), do: msg

  def message(%__MODULE__{status: status, code: nil, message: msg}),
    do: "[#{status}] #{msg}"

  def message(%__MODULE__{status: status, code: code, message: msg}),
    do: "[#{status}] #{code}: #{msg}"

  @doc """
  Builds a `Miosa.Error` from a `Req.Response` struct.

  Parses the JSON body for `"error"` and `"code"` keys following the
  MIOSA API error envelope format.
  """
  @spec from_response(Req.Response.t()) :: t()
  def from_response(%Req.Response{status: status, body: body}) do
    {message, code} = extract_fields(body)

    %__MODULE__{
      message: message,
      status: status,
      code: code,
      body: if(is_map(body), do: body, else: nil)
    }
  end

  @doc """
  Builds a `Miosa.Error` for non-HTTP failures (network errors, decode errors).
  """
  @spec from_exception(Exception.t() | term()) :: t()
  def from_exception(exception) do
    %__MODULE__{
      message: Exception.message(exception),
      status: nil,
      code: nil,
      body: nil
    }
  end

  # --- private ---

  defp extract_fields(%{"error" => msg, "code" => code}), do: {msg, code}
  defp extract_fields(%{"error" => msg}), do: {msg, nil}
  defp extract_fields(%{"message" => msg, "code" => code}), do: {msg, code}
  defp extract_fields(%{"message" => msg}), do: {msg, nil}
  defp extract_fields(%{"errors" => [msg | _]}) when is_binary(msg), do: {msg, nil}
  defp extract_fields(_), do: {"Unexpected API error", nil}
end
