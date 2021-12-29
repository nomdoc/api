defmodule APIWeb.EnforceJobListingAccessMiddleware do
  @moduledoc """
  A middleware that checks whether or not the currently viewing user can manage
  the job listing.

  ## Notes

  - query / mutation `args` must contain `job_id` field.
  - `current_user` must be present in resolution. Use
    `APIWeb.EnsureAuthenticatedMiddleware` to perform checking.
  """

  @behaviour Absinthe.Middleware

  import Ecto.Changeset
  import API.Utils
  import APIWeb.SchemaHelpers

  alias API.JobListing
  alias API.User
  alias APIWeb.EnsureAuthenticatedMiddleware
  alias Ecto.Changeset

  @impl Absinthe.Middleware
  def call(%Absinthe.Resolution{} = resolution, _config) do
    if EnsureAuthenticatedMiddleware.continue?(resolution) do
      current_user = get_current_user!(resolution)
      data = %{job_id: Map.get(resolution.arguments, :job_id)}
      types = %{job_id: :string}
      params = Map.keys(types)

      {%{}, types}
      |> cast(data, params)
      |> parse_string(:job_id, scrub: :all)
      |> case do
        %Changeset{valid?: true} = changeset ->
          %{job_id: job_id} = apply_changes(changeset)

          if access?(current_user, job_id) do
            resolution
          else
            Absinthe.Resolution.put_result(resolution, {:error, :unauthorized})
          end

        _changeset ->
          raise ArgumentError, message: "missing 'job_id'."
      end
    else
      resolution
    end
  end

  defp access?(%User{} = user, job_id) do
    user.role in [:superuser, :admin] || JobListing.access?(user.id, job_id)
  end
end
