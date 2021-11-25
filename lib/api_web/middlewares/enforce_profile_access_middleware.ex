defmodule APIWeb.EnforceProfileAccessMiddleware do
  @moduledoc """
  A middleware that checks whether or not the currently viewing user can manage
  the profile.

  ## Notes

  - query / mutation `args` must contain `handle_name` field.
  - `current_user` must be present in resolution. Use
    `APIWeb.EnsureAuthenticatedMiddleware` to perform checking.
  """

  @behaviour Absinthe.Middleware

  import Ecto.Changeset
  import API.Utils
  import APIWeb.SchemaHelpers

  alias API.HandleNames
  alias APIWeb.EnsureAuthenticatedMiddleware
  alias Ecto.Changeset

  @impl Absinthe.Middleware
  def call(%Absinthe.Resolution{} = resolution, _config) do
    if EnsureAuthenticatedMiddleware.continue?(resolution) do
      current_user = get_current_user!(resolution)
      data = %{handle_name: Map.get(resolution.arguments, :handle_name)}
      types = %{handle_name: :string}
      params = Map.keys(types)

      {%{}, types}
      |> cast(data, params)
      |> parse_string(:handle_name, scrub: :all, transform: :downcase)
      |> validate_format(:handle_name, API.Regex.handle_name())
      |> case do
        %Changeset{valid?: true} = changeset ->
          %{handle_name: handle_name} = apply_changes(changeset)

          if HandleNames.access?(handle_name, current_user) do
            resolution
          else
            Absinthe.Resolution.put_result(resolution, {:error, :unauthorized})
          end

        _changeset ->
          raise ArgumentError, message: "missing 'handle_name'."
      end
    else
      resolution
    end
  end
end
