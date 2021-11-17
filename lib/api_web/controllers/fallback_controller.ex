defmodule APIWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.
  See `Phoenix.Controller.action_fallback/1` for more details.
  """

  use APIWeb, :controller

  # https://shyr.io/blog/absinthe-exception-error-handling
  def call(conn, {:error, error}) do
    error = APIWeb.ErrorHandler.normalize(error)

    conn
    |> put_status(error.status_code)
    |> json(error)
  end
end
