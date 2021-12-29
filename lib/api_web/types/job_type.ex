defmodule APIWeb.JobType do
  @moduledoc false

  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [on_load: 2]
  import APIWeb.SchemaHelpers

  alias API.Countries
  alias API.Job
  alias API.JobListing
  alias API.Pagination
  alias API.Recruiter
  alias API.User

  enum :job_employment_type do
    value(:locum, description: "Temporary work shift.")

    value(:full_time,
      description:
        "Full-time employment typically has a set work week and provides social security and welfare benefits."
    )
  end

  enum :job_status do
    value(:draft)
    value(:published)
    value(:unpublished)
  end

  object :job_address do
    field :latitude, non_null(:float)

    field :longitude, non_null(:float)

    field :line_one, non_null(:string)

    field :line_two, :string

    field :city, non_null(:string)

    field :state, non_null(:string)

    field :postal_code, non_null(:string)

    field :country, non_null(:country), resolve: &country/3
  end

  object :job do
    @desc "The job's ID."
    field :id, non_null(:id)

    @desc "The employment type of the job."
    field :employment_type, non_null(:job_employment_type)

    @desc "The status of the job."
    field :status, :job_status, resolve: &status/3

    @desc "The job title."
    field :title, non_null(:string)

    @desc "The job description."
    field :description, :string

    field :address, :job_address, resolve: &address/3
  end

  object :job_edge do
    @desc "A cursor for use in pagination."
    field :cursor, non_null(:string)

    @desc "The item at the end of the edge."
    field :node, :job
  end

  object :job_connection do
    @desc "Identifies the total count of items in the connection."
    field :total_count, non_null(:integer), resolve: &total_count/3

    @desc "Information to aid in pagination."
    field :page_info, non_null(:page_info)

    @desc "A list of edges."
    field :edges, list_of(:job_edge)
  end

  defp status(%Job{} = job, _args, resolution) do
    case get_current_user(resolution) do
      {:ok, %User{} = current_user} ->
        resolution
        |> get_loader!()
        |> Dataloader.load(:repo, :recruiter, job)
        |> on_load(fn loader ->
          recruiter = Dataloader.get(loader, :repo, :recruiter, job)

          if access_job?(recruiter, current_user) do
            {:ok, job.status}
          else
            {:ok, nil}
          end
        end)

      _reply ->
        {:ok, nil}
    end
  end

  defp address(%Job{} = job, _args, _resolution) do
    address_filled_up? =
      Map.take(job, [
        :address_latitude,
        :address_longitude,
        :address_line_one,
        :address_city,
        :address_state,
        :address_postal_code,
        :address_country_code
      ])
      |> Map.values()
      |> Enum.all?()

    if address_filled_up? do
      {:ok,
       %{
         latitude: job.address_latitude,
         longitude: job.address_longitude,
         line_one: job.address_line_one,
         line_two: job.address_line_two,
         city: job.address_city,
         state: job.address_state,
         postal_code: job.address_postal_code,
         country_code: job.address_country_code
       }}
    else
      {:ok, nil}
    end
  end

  defp country(address, _args, _resolution) do
    {:ok, Countries.get_by(code: address.country_code)}
  end

  defp total_count(%Pagination{} = pagination, _args, _resolution) do
    JobListing.count_listings(pagination.metadata.entity_id)
  end

  defp access_job?(%Recruiter{} = recruiter, %User{} = current_user) do
    current_user.role in [:superuser, :admin] or current_user.id == recruiter.entity_id
  end
end
