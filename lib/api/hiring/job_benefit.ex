defmodule API.JobBenefit do
  @moduledoc false

  use API, :model

  alias API.Job

  schema "job_benefit" do
    belongs_to :job, Job
    timestamps()
  end
end
