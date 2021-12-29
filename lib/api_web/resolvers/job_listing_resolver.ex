defmodule APIWeb.JobListingResolver do
  @moduledoc false

  use APIWeb, :resolver

  object :job_listing_queries do
    field :job, :job do
      arg(:id, non_null(:uuid4))
      resolve(&job/2)
    end
  end

  object :job_listing_mutations do
    field :post_job, non_null(:post_job_payload) do
      arg(:input, non_null(:post_job_input))
      middleware(EnsureAuthenticatedMiddleware)
      resolve(&post_job/2)
    end

    field :edit_job_basic_info, non_null(:edit_job_basic_info_payload) do
      arg(:job_id, non_null(:string))
      arg(:input, non_null(:edit_job_basic_info_input))
      middleware(EnsureAuthenticatedMiddleware)
      middleware(EnforceJobListingAccessMiddleware)
      resolve(&edit_job_basic_info/2)
    end

    field :edit_job_address, non_null(:edit_job_address_payload) do
      arg(:job_id, non_null(:string))
      arg(:input, non_null(:edit_job_address_input))
      middleware(EnsureAuthenticatedMiddleware)
      middleware(EnforceJobListingAccessMiddleware)
      resolve(&edit_job_address/2)
    end

    # TODO Dec 29: Edit job payment + incentives
    # TODO Dec 29: Publish job
    # TODO Dec 29: Unlist job
    # TODO Dec 29: Edit job work time
  end

  # ----------
  # Queries
  # ----------

  defp job(args, _resolution) do
    case Repo.get(Job, args.id) do
      %Job{} = job -> {:ok, job}
      nil -> {:ok, nil}
    end
  end

  # ----------
  # Mutations
  # ----------

  input_object :post_job_input do
    field :employment_type, non_null(:job_employment_type)
    field :title, non_null(:string)
  end

  object :post_job_payload do
    field :job, non_null(:job)
  end

  defp post_job(args, resolution) do
    inputs = args.input
    types = %{title: :string}
    params = Map.keys(types)
    current_user = get_current_user!(resolution)

    {%{}, types}
    |> cast(inputs, params)
    |> parse_string(:title)
    |> validate_length(:title, min: 5, max: 150)
    |> case do
      %Ecto.Changeset{valid?: true} = changeset ->
        data = apply_changes(changeset)
        details = %{employment_type: inputs.employment_type, title: data.title}

        with {:ok, job} <- JobListing.post_job(current_user.id, details),
             do: {:ok, %{job: job}}

      changeset ->
        {:error, changeset}
    end
  end

  input_object :edit_job_basic_info_input do
    field :title, non_null(:string)
    field :description, non_null(:string)
  end

  object :edit_job_basic_info_payload do
    field :job, non_null(:job)
  end

  defp edit_job_basic_info(args, _resolution) do
    inputs = Map.put(args.input, :job_id, args.job_id)
    types = %{job_id: :string, title: :string, description: :string}
    params = Map.keys(types)

    {%{}, types}
    |> cast(inputs, params)
    |> parse_string(:job_id)
    |> parse_string(:title)
    |> parse_string(:description)
    |> validate_length(:title, min: 5, max: 150)
    |> validate_length(:description, min: 5, max: 500)
    |> case do
      %Ecto.Changeset{valid?: true} = changeset ->
        data = apply_changes(changeset)
        basic_info = %{title: data.title, description: data.description}

        with {:ok, job} <- JobListing.edit_job_basic_info(data.job_id, basic_info),
             do: {:ok, %{job: job}}

      changeset ->
        {:error, changeset}
    end
  end

  input_object :edit_job_address_input do
    field :latitude, non_null(:float)
    field :longitude, non_null(:float)
    field :line_one, non_null(:string)
    field :line_two, :string
    field :city, non_null(:string)
    field :state, non_null(:string)
    field :postal_code, non_null(:string)
    field :country_code, non_null(:string)
  end

  object :edit_job_address_payload do
    field :job, non_null(:job)
  end

  defp edit_job_address(args, _resolution) do
    inputs = Map.put(args.input, :job_id, args.job_id)

    types = %{
      job_id: :string,
      latitude: :float,
      longitude: :float,
      line_one: :string,
      line_two: :string,
      city: :string,
      state: :string,
      postal_code: :string,
      country_code: :string
    }

    params = Map.keys(types)

    {%{}, types}
    |> cast(inputs, params)
    |> parse_string(:job_id)
    |> parse_string(:line_one)
    |> parse_string(:line_two)
    |> parse_string(:city)
    |> parse_string(:state)
    |> parse_string(:postal_code)
    |> parse_string(:country_code, scrub: :all, transform: :downcase)
    |> validate_length(:line_one, min: 1, max: 250)
    |> validate_length(:line_two, min: 1, max: 250)
    |> validate_length(:city, min: 1, max: 250)
    |> validate_length(:state, min: 1, max: 250)
    |> validate_length(:postal_code, min: 2, max: 10)
    |> validate_assertion(:country_code, &Countries.valid?(code: &1), message: "is not valid")
    |> case do
      %Ecto.Changeset{valid?: true} = changeset ->
        data = apply_changes(changeset)

        coordinate = %{latitude: data.latitude, longitude: data.longitude}

        address = %{
          line_one: data.line_one,
          line_two: Map.get(data, :line_two),
          city: data.city,
          state: data.state,
          postal_code: data.postal_code,
          country_code: data.country_code
        }

        with {:ok, job} <- JobListing.edit_job_address(data.job_id, coordinate, address),
             do: {:ok, %{job: job}}

      changeset ->
        {:error, changeset}
    end
  end
end
