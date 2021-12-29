defmodule API.JobCompensation do
  @moduledoc false

  use API, :model

  alias API.Job

  schema "job_compensation" do
    belongs_to :job, Job
    timestamps()
  end
end
