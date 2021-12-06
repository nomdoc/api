defmodule API.JobListings do
  @moduledoc false

  use API, :context

  alias API.Job
  alias API.Recruiter
  alias API.Recruiters

  @spec create_job(binary(), %{employment_type: Job.EmploymentType.t(), title: binary()}) ::
          {:ok, Job.t()}
  def create_job(entity_id, job_details) do
    with {:ok, recruiter} <- Recruiters.get_recruiter(entity_id),
         {:ok, new_job} <- create_draft_job(recruiter, job_details),
         do: {:ok, new_job}
  end

  defp create_draft_job(%Recruiter{} = recruiter, job_details) do
    job_id = Ecto.UUID.generate()
    job_details = Map.put(job_details, :id, job_id)

    new_job =
      recruiter
      |> Recruiter.draft_job(job_details)
      |> Repo.update!()
      |> Map.get(:jobs)
      |> Enum.find(&(&1.id == job_id))

    {:ok, new_job}
  end
end
