defmodule APIWeb.EnsureAuthenticatedMiddleware do
  @moduledoc """
  A middleware that checks whether or not the currently viewing user is logged
  in.
  """

  @behaviour Absinthe.Middleware

  @impl Absinthe.Middleware
  def call(%Absinthe.Resolution{} = resolution, _config) do
    case resolution.context do
      %{current_user: %API.User{}} -> resolution
      _context -> Absinthe.Resolution.put_result(resolution, {:error, :unauthenticated})
    end
  end

  @doc """
  Indicates whether middleware should continue to resolve or just stop.

  ## Examples

      defmodule SomeMiddleware do
        @behaviour Absinthe.Middleware

        def call(resolution, config) do
          # Here we check whether `SomeMiddleware` should continue to resolve or not.
          if EnsureAuthenticatedMiddleware.continue?(resolution) do
            # Resolve whatever
          else
            # There's already an `unauthenticated` error.
            # Don't need to do anything. Just return the resolution.
            resolution
          end
        end
      end
  """
  @spec continue?(Absinthe.Resolution.t()) :: boolean()
  def continue?(%Absinthe.Resolution{} = resolution) do
    :unauthenticated not in resolution.errors
  end
end
