defmodule APIWeb.ProfileResolver do
  @moduledoc false

  use APIWeb, :resolver

  object :profile_queries do
    field :profile, :profile do
      arg(:handle_name, non_null(:string))
      resolve(&profile/2)
    end
  end

  object :profile_mutations do
    field :validate_handle_name, non_null(:validate_handle_name_payload) do
      arg(:handle_name, non_null(:string))
      resolve(&validate_handle_name/2)
    end

    field :update_handle_name, :update_handle_name_payload do
      arg(:handle_name, non_null(:string))
      arg(:input, non_null(:update_handle_name_input))
      middleware(EnsureAuthenticatedMiddleware)
      middleware(EnforceProfileAccessMiddleware)
      resolve(&update_handle_name/2)
    end

    field :update_display_name, :update_display_name_payload do
      arg(:handle_name, non_null(:string))
      arg(:input, non_null(:update_display_name_input))
      middleware(EnsureAuthenticatedMiddleware)
      middleware(EnforceProfileAccessMiddleware)
      resolve(&update_display_name/2)
    end

    field :update_bio, :update_bio_payload do
      arg(:handle_name, non_null(:string))
      arg(:input, non_null(:update_bio_input))
      middleware(EnsureAuthenticatedMiddleware)
      middleware(EnforceProfileAccessMiddleware)
      resolve(&update_bio/2)
    end
  end

  union :profile do
    types([:user, :organization])

    resolve_type(fn
      %API.User{}, _resolution -> :user
      %API.Organization{}, _resolution -> :organization
    end)
  end

  # ----------
  # Queries
  # ----------

  defp profile(args, _resolution) do
    data = args
    types = %{handle_name: :string}
    params = Map.keys(types)

    {%{}, types}
    |> cast(data, params)
    |> parse_string(:handle_name, scrub: :all, transform: :downcase)
    |> validate_format(:handle_name, API.Regex.handle_name())
    |> case do
      %Changeset{valid?: true} = changeset ->
        %{handle_name: handle_name} = apply_changes(changeset)

        HandleNames.get_account(handle_name)

      changeset ->
        {:error, changeset}
    end
  end

  # ----------
  # Mutations
  # ----------

  object :validate_handle_name_payload do
    field :handle_name, non_null(:string)
  end

  defp validate_handle_name(args, _resolution) do
    data = args
    types = %{handle_name: :string}
    params = Map.keys(types)

    {%{}, types}
    |> cast(data, params)
    |> parse_string(:handle_name, scrub: :all, transform: :downcase)
    |> validate_format(:handle_name, API.Regex.handle_name())
    |> case do
      %Ecto.Changeset{valid?: true} = changeset ->
        %{handle_name: handle_name} = apply_changes(changeset)

        with :ok <- API.HandleNames.validate_handle_name(handle_name),
             do: {:ok, %{handle_name: handle_name}}

      changeset ->
        {:error, changeset}
    end
  end

  input_object :update_handle_name_input do
    field :new_handle_name, non_null(:string)
  end

  object :update_handle_name_payload do
    field :handle_name, non_null(:string)
  end

  defp update_handle_name(args, _resolution) do
    %{handle_name: handle_name, input: input} = args
    data = Map.put(input, :handle_name, handle_name)
    types = %{handle_name: :string, new_handle_name: :string}
    params = Map.keys(types)

    {%{}, types}
    |> cast(data, params)
    |> parse_string(:handle_name, scrub: :all, transform: :downcase)
    |> parse_string(:new_handle_name, scrub: :all, transform: :downcase)
    |> validate_format(:handle_name, API.Regex.handle_name())
    |> validate_format(:new_handle_name, API.Regex.handle_name())
    |> case do
      %Ecto.Changeset{valid?: true} = changeset ->
        %{handle_name: handle_name, new_handle_name: new_handle_name} = apply_changes(changeset)

        case HandleNames.get_account(handle_name) do
          {:ok, %User{id: user_id}} ->
            with {:ok, %User{}} <- Users.update_handle_name(user_id, new_handle_name),
                 do: {:ok, %{handle_name: new_handle_name}}

          {:ok, %Organization{id: org_id}} ->
            with {:ok, %Organization{}} <-
                   Organizations.update_handle_name(org_id, new_handle_name),
                 do: {:ok, %{handle_name: new_handle_name}}

          reply ->
            reply
        end

      changeset ->
        {:error, changeset}
    end
  end

  input_object :update_display_name_input do
    field :display_name, non_null(:string)
  end

  object :update_display_name_payload do
    field :display_name, non_null(:string)
  end

  defp update_display_name(args, _resolution) do
    %{handle_name: handle_name, input: input} = args
    data = Map.put(input, :handle_name, handle_name)
    types = %{handle_name: :string, display_name: :string}
    params = Map.keys(types)

    {%{}, types}
    |> cast(data, params)
    |> parse_string(:handle_name, scrub: :all, transform: :downcase)
    |> parse_string(:display_name)
    |> validate_format(:handle_name, API.Regex.handle_name())
    |> validate_length(:display_name, max: 255)
    |> case do
      %Ecto.Changeset{valid?: true} = changeset ->
        %{handle_name: handle_name, display_name: display_name} = apply_changes(changeset)

        case HandleNames.get_account(handle_name) do
          {:ok, %User{id: user_id}} ->
            with {:ok, %User{}} <- Users.update_display_name(user_id, display_name),
                 do: {:ok, %{display_name: display_name}}

          {:ok, %Organization{id: org_id}} ->
            with {:ok, %Organization{}} <-
                   Organizations.update_display_name(org_id, display_name),
                 do: {:ok, %{display_name: display_name}}

          reply ->
            reply
        end

      changeset ->
        {:error, changeset}
    end
  end

  input_object :update_bio_input do
    field :bio, non_null(:string)
  end

  object :update_bio_payload do
    field :bio, non_null(:string)
  end

  defp update_bio(args, _resolution) do
    %{handle_name: handle_name, input: input} = args
    data = Map.put(input, :handle_name, handle_name)
    types = %{handle_name: :string, bio: :string}
    params = Map.keys(types)

    {%{}, types}
    |> cast(data, params)
    |> parse_string(:handle_name, scrub: :all, transform: :downcase)
    |> parse_string(:bio, message: "Invalid bio.")
    |> validate_format(:handle_name, API.Regex.handle_name())
    |> validate_length(:bio, max: 255)
    |> case do
      %Ecto.Changeset{valid?: true} = changeset ->
        %{handle_name: handle_name, bio: bio} = apply_changes(changeset)

        case HandleNames.get_account(handle_name) do
          {:ok, %User{id: user_id}} ->
            with {:ok, %User{}} <- Users.update_bio(user_id, bio),
                 do: {:ok, %{bio: bio}}

          {:ok, %Organization{id: org_id}} ->
            with {:ok, %Organization{}} <- Organizations.update_bio(org_id, bio),
                 do: {:ok, %{bio: bio}}

          reply ->
            reply
        end

      changeset ->
        {:error, changeset}
    end
  end
end
