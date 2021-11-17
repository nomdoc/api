defmodule APIWeb.EnforceOrganizationAccessMiddleware do
  @moduledoc """
  A middleware that checks whether or not the currently viewing user can manage
  the organization.

  ## Notes

  - query / mutation `args` must contain `organization_id` field.
  - `current_user` must be present in resolution. Use
    `APIWeb.EnsureAuthenticatedMiddleware` to perform checking.
  """

  @behaviour Absinthe.Middleware

  import Ecto.Changeset
  import API.Utils
  import APIWeb.Utils

  alias API.Organizations
  alias APIWeb.EnsureAuthenticatedMiddleware
  alias Ecto.Changeset

  @impl Absinthe.Middleware
  def call(%Absinthe.Resolution{} = resolution, _config) do
    if EnsureAuthenticatedMiddleware.continue?(resolution) do
      current_user = get_current_user!(resolution)
      data = %{organization_id: Map.get(resolution.arguments, :organization_id)}
      types = %{organization_id: :string}
      params = Map.keys(types)

      {%{}, types}
      |> cast(data, params)
      |> parse_string(:organization_id, scrub: :all)
      |> case do
        %Changeset{valid?: true} = changeset ->
          %{organization_id: organization_id} = apply_changes(changeset)

          with {:ok, organization} <- Organizations.get_by_id(organization_id),
               true <- Organizations.access?(organization, current_user) do
            resolution
          else
            _reply ->
              Absinthe.Resolution.put_result(resolution, {:error, :unauthorized})
          end

        _changeset ->
          raise ArgumentError, message: "missing 'organization_id'."
      end
    else
      resolution
    end
  end
end
