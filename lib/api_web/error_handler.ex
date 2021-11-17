defmodule APIWeb.ErrorHandler do
  @moduledoc false

  require Logger

  @doc """
  Normalize error response to Absinthe error payload.
  """
  @spec normalize(atom() | Ecto.Changeset.t() | {:error, atom() | Ecto.Changeset.t()}) :: %{
          code: atom(),
          message: binary(),
          status_code: 400 | 401 | 403 | 404 | 422 | 429 | 500,
          errors: list()
        }
  def normalize(error) do
    case error do
      code when is_atom(code) -> handle(code)
      %Ecto.Changeset{} = changeset -> handle(changeset)
      {:error, code} when is_atom(code) -> handle(code)
      {:error, %Ecto.Changeset{} = changeset} -> handle(changeset)
    end
  end

  defp handle(code) when is_atom(code) do
    case metadata(code) do
      {status_code, message} -> create_error(code, status_code, message)
      {status_code, public_code, message} -> create_error(public_code, status_code, message)
    end
  end

  defp handle(%Ecto.Changeset{} = changeset) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Enum.reduce(opts, msg, fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end)
      end)
      |> Keyword.new()
      |> Enum.map(fn {k, v} when is_map(v) ->
        # When `v` is something like this %{value: ["has already been taken"]}
        %{
          field: Accent.Case.Camel.call(k),
          message: v |> Keyword.new() |> List.first() |> elem(1) |> List.first()
        }
      end)

    create_error(:failed_validation, 422, "Failed validation.", errors)
  end

  defp create_error(code, status_code, message) do
    %{code: code, status_code: status_code, message: message}
  end

  defp create_error(code, status_code, message, errors) do
    %{code: code, status_code: status_code, message: message, errors: errors}
  end

  # 400 Bad Request
  # 401 Unauthorized
  # 402 Payment Required
  # 403 Forbidden
  # 404 Not Found
  # 422 Unprocessable Entity
  # 429 Too Many Requests
  # 500 Internal Server Error

  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp metadata(code) do
    case code do
      :bad_request -> {400, "Bad request."}
      :unauthenticated -> {401, "Please login to continue"}
      :unauthorized -> {403, "Please make sure you have sufficient permissions."}
      :not_found -> {404, "Resource not found."}
      :unknown -> {500, :internal_server_error, "Internal server error."}
      :internal_server_error -> {500, "Internal server error"}
      :invalid_pagination_cursor -> {422, "Unable to decode pagination cursor."}
      :unsupported_response_type -> {422, "Please provide valid response type."}
      :unsupported_grant_type -> {422, "Please provide valid grant type."}
      :invalid_json -> {400, "Invalid JSON."}
      :login_failed -> {422, "Unable to login, please try again later."}
      :account_not_found -> {404, "Unable to find account."}
      reply -> handle_unhandled_code(reply)
    end
  end

  defp handle_unhandled_code(code) do
    if Application.fetch_env!(:api, :compiled_env) in [:dev, :test] do
      raise RuntimeError, message: "Unhandled error code: #{inspect(code)}."
    else
      Logger.error("Unhandled error code: #{inspect(code)}")

      {422, "Unable to process request."}
    end
  end
end
