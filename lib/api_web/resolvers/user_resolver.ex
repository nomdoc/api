defmodule APIWeb.UserResolver do
  @moduledoc false

  use APIWeb, :resolver

  object :user_queries do
    @desc "The currently authenticated user."
    field :viewer, :user do
      middleware(EnsureAuthenticatedMiddleware)
      resolve(&viewer/2)
    end
  end

  # ----------
  # Queries
  # ----------

  defp viewer(_args, resolution) do
    {:ok, get_current_user!(resolution)}
  end
end
