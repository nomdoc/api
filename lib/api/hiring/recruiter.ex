defmodule API.Recruiter do
  @moduledoc false

  use API, :model

  alias API.Job

  schema "recruiter" do
    field :entity_id, :string
    field :new?, :boolean, virtual: true, default: false

    has_many :jobs, Job

    timestamps()
  end

  @spec changeset(t(), data) :: Changeset.t() when data: %{id: binary(), entity_id: binary()}
  def changeset(%__MODULE__{} = recruiter, data) do
    params = ~w(id entity_id)a

    recruiter
    |> cast(data, params)
    |> validate_required(params)
    |> unique_constraint(:entity_id)
  end

  @spec draft_job(t(), job_details) :: Changeset.t()
        when job_details: %{
               id: binary(),
               employment_type: Job.EmploymentType.t(),
               title: binary()
             }
  def draft_job(%__MODULE__{} = recruiter, job_details) do
    recruiter = Repo.preload(recruiter, [:jobs])
    job = Map.put(job_details, :recruiter_id, recruiter.id)

    data = %{
      jobs:
        recruiter.jobs
        |> Enum.map(&convert_struct_to_map/1)
        |> Enum.concat([job])
    }

    recruiter
    |> cast(data, [])
    |> cast_assoc(:jobs)
  end
end
