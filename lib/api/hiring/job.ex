defmodule API.Job do
  @moduledoc false

  use API, :model

  alias API.JobApplication
  alias API.JobBenefit
  alias API.JobCompensation
  alias API.Recruiter

  defenum(Status, draft: 0, published: 1, unpublished: 2)
  defenum(EmploymentType, full_time: 0, part_time: 1)

  schema "job" do
    belongs_to :recruiter, Recruiter
    field :status, Status, default: :draft

    field :employment_type, EmploymentType
    # TODO shifts?
    belongs_to :parent_job, __MODULE__

    field :title, :string
    field :description, :string

    field :time_zone, :string
    field :starts_at, :utc_datetime_usec
    field :ends_at, :utc_datetime_usec

    field :address_latitude, :float
    field :address_longitude, :float
    field :address_line_one, :string
    field :address_line_two, :string
    field :address_city, :string
    field :address_state, :string
    field :address_postal_code, :string
    field :address_country_code, :string

    has_many :benefits, JobBenefit
    has_many :compensations, JobCompensation
    has_many :applications, JobApplication

    # TODO incentives
    # TODO responsibilities
    # TODO qualifications

    timestamps()
  end

  @spec changeset(t(), data) :: Changeset.t()
        when data: %{
               id: binary(),
               recruiter_id: binary(),
               employment_type: EmploymentType.t(),
               title: binary()
             }
  def changeset(%__MODULE__{} = job, data) do
    params = ~w(id recruiter_id employment_type title)a

    job
    |> cast(data, params)
    |> validate_required(params)
    |> validate_enum(:employment_type)
    |> foreign_key_constraint(:recruiter_id)
  end
end
