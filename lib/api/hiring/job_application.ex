defmodule API.JobApplication do
  @moduledoc false

  use API, :model

  alias API.Applicant
  alias API.Job

  schema "job_application" do
    belongs_to :job, Job
    belongs_to :applicant, Applicant
    timestamps()
  end
end
