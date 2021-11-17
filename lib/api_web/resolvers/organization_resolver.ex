defmodule APIWeb.OrganizationResolver do
  @moduledoc false

  use APIWeb, :resolver

  object :organization_mutations do
    field :register_organization, :register_organization_payload do
      arg(:input, non_null(:register_organization_input))
      middleware(EnsureAuthenticatedMiddleware)
      resolve(&register_organization/2)
    end

    field :invite_organization_member, :invite_organization_member_payload do
      arg(:organization_id, non_null(:uuid4))
      arg(:input, non_null(:invite_organization_member_input))
      middleware(EnsureAuthenticatedMiddleware)
      middleware(EnforceOrganizationAccessMiddleware)
      resolve(&invite_organization_member/2)
    end

    field :remove_organization_invite, :remove_organization_invite_payload do
      arg(:organization_id, non_null(:uuid4))
      arg(:input, non_null(:remove_organization_invite_input))
      middleware(EnsureAuthenticatedMiddleware)
      middleware(EnforceOrganizationAccessMiddleware)
      resolve(&remove_organization_invite/2)
    end

    field :remove_organization_member, :remove_organization_member_payload do
      arg(:organization_id, non_null(:uuid4))
      arg(:input, non_null(:remove_organization_member_input))
      middleware(EnsureAuthenticatedMiddleware)
      middleware(EnforceOrganizationAccessMiddleware)
      resolve(&remove_organization_member/2)
    end

    field :accept_organization_invite, :accept_organization_invite_payload do
      arg(:input, non_null(:accept_organization_invite_input))
      middleware(EnsureAuthenticatedMiddleware)
      resolve(&accept_organization_invite/2)
    end

    field :reject_organization_invite, :reject_organization_invite_payload do
      arg(:input, non_null(:reject_organization_invite_input))
      middleware(EnsureAuthenticatedMiddleware)
      resolve(&reject_organization_invite/2)
    end

    field :leave_organization, :leave_organization_payload do
      arg(:input, non_null(:leave_organization_input))
      middleware(EnsureAuthenticatedMiddleware)
      resolve(&leave_organization/2)
    end
  end

  # ----------
  # Mutations
  # ----------

  input_object :register_organization_input do
    field :handle_name, non_null(:string)
  end

  object :register_organization_payload do
    @desc "The user that owns the created organization."
    field :owner, non_null(:user)

    @desc "The organization that was created."
    field :organization, non_null(:organization)
  end

  defp register_organization(%{input: input}, resolution) do
    types = %{handle_name: :string}
    params = Map.keys(types)
    current_user = get_current_user!(resolution)

    {%{}, types}
    |> cast(input, params)
    |> parse_string(:handle_name, scrub: :all, transform: :downcase)
    |> validate_format(:handle_name, API.Regex.handle_name())
    |> case do
      %Changeset{valid?: true} = changeset ->
        %{handle_name: handle_name} = apply_changes(changeset)

        with {:ok, organization} <-
               Organizations.register_organization(handle_name, current_user.id),
             do: {:ok, %{owner: current_user, organization: organization}}

      changeset ->
        {:error, changeset}
    end
  end

  input_object :invite_organization_member_input do
    field :user_id, :uuid4
    field :email_address, :string
    field :role, non_null(:organization_membership_role)
  end

  object :invite_organization_member_payload do
    field :invite, non_null(:organization_invite)
  end

  defp invite_organization_member(args, _resolution) do
    %{organization_id: organization_id, input: input} = args

    data =
      input
      |> Map.put(:organization_id, organization_id)
      |> Map.put(:role, Map.get(input, :role) |> Atom.to_string())

    types = %{organization_id: :string, user_id: :string, email_address: :string, role: :string}
    params = Map.keys(types)

    {%{}, types}
    |> cast(data, params)
    |> parse_string(:organization_id, scrub: :all)
    |> parse_string(:user_id, scrub: :all, optional?: true)
    |> parse_string(:email_address, scrub: :all, optional?: true)
    |> validate_required_one_of([:user_id, :email_address])
    |> validate_format(:email_address, API.Regex.email_address())
    |> case do
      %Changeset{valid?: true} = changeset ->
        %{organization_id: organization_id, role: role} = data = apply_changes(changeset)

        user_id = Map.get(data, :user_id)
        email_address = Map.get(data, :email_address)

        cond do
          is_binary(user_id) ->
            with {:ok, org_invite} <-
                   API.Organizations.invite_member_by_user_id(organization_id, user_id, role),
                 do: {:ok, %{invite: org_invite}}

          is_binary(email_address) ->
            with {:ok, org_invite} <-
                   API.Organizations.invite_member_by_email_address(
                     organization_id,
                     email_address,
                     role
                   ),
                 do: {:ok, %{invite: org_invite}}
        end

      changeset ->
        {:error, changeset}
    end
  end

  input_object :remove_organization_invite_input do
    field :user_id, non_null(:uuid4)
  end

  object :remove_organization_invite_payload do
    field :invite, non_null(:organization_invite)
  end

  defp remove_organization_invite(args, _resolution) do
    organization_id = args.organization_id
    user_id = args.input.user_id

    with {:ok, invite} <- Organizations.remove_invite(organization_id, user_id),
         do: {:ok, %{invite: invite}}
  end

  input_object :remove_organization_member_input do
    field :user_id, non_null(:uuid4)
  end

  object :remove_organization_member_payload do
    field :membership, non_null(:organization_membership)
  end

  defp remove_organization_member(args, _resolution) do
    organization_id = args.organization_id
    user_id = args.input.user_id

    with {:ok, membership} <- Organizations.remove_member(organization_id, user_id),
         do: {:ok, %{membership: membership}}
  end

  input_object :accept_organization_invite_input do
    field :organization_id, non_null(:uuid4)
  end

  object :accept_organization_invite_payload do
    field :membership, non_null(:organization_membership)
  end

  defp accept_organization_invite(args, resolution) do
    current_user = get_current_user!(resolution)
    organization_id = args.input.organization_id

    with {:ok, membership} <- Organizations.accept_invite(organization_id, current_user.id),
         do: {:ok, %{membership: membership}}
  end

  input_object :reject_organization_invite_input do
    field :organization_id, non_null(:uuid4)
  end

  object :reject_organization_invite_payload do
    field :invite, non_null(:organization_invite)
  end

  defp reject_organization_invite(args, resolution) do
    current_user = get_current_user!(resolution)
    organization_id = args.input.organization_id

    with {:ok, invite} <- Organizations.remove_invite(organization_id, current_user.id),
         do: {:ok, %{invite: invite}}
  end

  input_object :leave_organization_input do
    field :organization_id, non_null(:uuid4)
  end

  object :leave_organization_payload do
    field :membership, non_null(:organization_membership)
  end

  defp leave_organization(args, resolution) do
    current_user = get_current_user!(resolution)
    organization_id = args.input.organization_id

    with {:ok, membership} <- Organizations.remove_member(organization_id, current_user.id),
         do: {:ok, %{membership: membership}}
  end
end
