defmodule APIWeb.NormalizeErrorMiddleware do
  @moduledoc """
  A middleware that converts error response from resolver to Absinthe error
  payload.

  For more information, see https://hexdocs.pm/absinthe/errors.html.
  """

  @behaviour Absinthe.Middleware

  @impl Absinthe.Middleware
  def call(%Absinthe.Resolution{} = resolution, _config) do
    %{resolution | errors: Enum.map(resolution.errors, &APIWeb.ErrorHandler.normalize/1)}
  end
end
