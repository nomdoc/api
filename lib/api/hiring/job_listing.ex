defmodule API.JobListing do
  @moduledoc false

  use API, :context

  alias API.Job
  alias API.Pagination
  alias API.Recruiter
  alias API.Recruiters

  @spec access?(binary(), binary()) :: boolean()
  def access?(entity_id, job_id) do
    case get_job_by_id(job_id, [:recruiter]) do
      {:ok, %Job{} = job} -> job.recruiter.entity_id == entity_id
      _reply -> false
    end
  end

  @spec post_job(binary(), details) ::
          {:ok, Job.t()}
        when details: %{employment_type: Job.EmploymentType.t(), title: binary()}
  def post_job(entity_id, details) do
    with {:ok, recruiter} <- Recruiters.get_recruiter(entity_id),
         {:ok, new_job} <- create_job(recruiter, details),
         do: {:ok, new_job}
  end

  defp create_job(%Recruiter{} = recruiter, details) do
    job_id = Ecto.UUID.generate()
    details = Map.put(details, :id, job_id)

    new_job =
      recruiter
      |> Recruiter.draft_job(details)
      |> Repo.update!()
      |> Map.get(:jobs)
      |> Enum.find(&(&1.id == job_id))

    {:ok, new_job}
  end

  @spec fetch_listings(binary(), Repo.pagination_opts()) ::
          {:ok, Pagination.t()} | {:error, :invalid_pagination_cursor}
  def fetch_listings(entity_id, opts \\ []) do
    query =
      from j in Job,
        join: r in Recruiter,
        on: j.recruiter_id == r.id,
        order_by: [desc: j.inserted_at],
        where: r.entity_id == ^entity_id

    default_opts = [sort_direction: :desc]
    opts = Keyword.merge(default_opts, opts)

    Repo.paginate(query, [:inserted_at, :id], opts)
  end

  @spec count_listings(binary()) :: {:ok, number()}
  def count_listings(entity_id) do
    query =
      from j in Job,
        join: r in Recruiter,
        on: j.recruiter_id == r.id,
        where: r.entity_id == ^entity_id

    Repo.total_count(query)
  end

  @spec edit_job_basic_info(binary(), basic_info) ::
          {:ok, Job.t()} | {:error, :job_not_found | :unable_to_edit_job | Changeset.t()}
        when basic_info: %{title: binary(), description: binary()}
  def edit_job_basic_info(job_id, basic_info) do
    case get_job_by_id(job_id) do
      {:ok, %Job{status: :published}} ->
        {:error, :unable_to_edit_job}

      {:ok, %Job{} = job} ->
        job
        |> Job.update_basic_info(basic_info)
        |> Repo.update()

      reply ->
        reply
    end
  end

  @spec edit_job_address(binary(), coordinate, address) ::
          {:ok, Job.t()} | {:error, :job_not_found}
        when coordinate: %{latitude: float(), longitude: float()},
             address: %{
               optional(:line_two) => binary(),
               line_one: binary(),
               city: binary(),
               state: binary(),
               postal_code: binary(),
               country_code: binary()
             }
  def edit_job_address(job_id, coordinate, address) do
    case get_job_by_id(job_id) do
      {:ok, %Job{status: :published}} ->
        {:error, :unable_to_edit_job}

      {:ok, %Job{} = job} ->
        data = %{
          address_latitude: coordinate.latitude,
          address_longitude: coordinate.longitude,
          address_line_one: address.line_one,
          address_line_two: Map.get(address, :line_two),
          address_city: address.city,
          address_state: address.state,
          address_postal_code: address.postal_code,
          address_country_code: address.country_code
        }

        job
        |> Job.update_address(data)
        |> Repo.update()

      reply ->
        reply
    end
  end

  defp get_job_by_id(job_id, preloads \\ []) do
    Repo.get(Job, job_id)
    |> Repo.preload(preloads)
    |> case do
      %Job{} = job -> {:ok, job}
      nil -> {:error, :job_not_found}
    end
  end
end
