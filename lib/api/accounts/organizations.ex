defmodule API.Organizations do
  @moduledoc false

  use API, :context

  alias API.HandleName
  alias API.Organization
  alias API.OrganizationInvite
  alias API.OrganizationMembership
  alias API.ReservedHandleName
  alias API.User
  alias API.Users
  alias API.Workers.SendOrganizationInviteEmail

  @spec access?(Organization.t(), User.t()) :: boolean()
  def access?(%Organization{} = organization, %User{} = user) do
    user.role == :superuser or member?(organization, user.id)
  end

  @spec ensure_access(Organization.t(), User.t()) :: :ok | {:error, :unauthorized}
  def ensure_access(%Organization{} = organization, %User{} = user) do
    if access?(organization, user),
      do: :ok,
      else: {:error, :unauthorized}
  end

  @spec member?(Organization.t(), binary()) :: boolean()
  def member?(%Organization{} = organization, user_id) do
    organization = Repo.preload(organization, [:memberships])

    case Enum.find(organization.memberships, &(&1.user_id == user_id)) do
      %OrganizationMembership{} -> true
      nil -> false
    end
  end

  @spec get_by_id(binary(), [term()]) ::
          {:ok, Organization.t()} | {:error, :organization_not_found}
  def get_by_id(organization_id, preloads \\ []) do
    Repo.get(Organization, organization_id)
    |> Repo.preload(preloads)
    |> case do
      %Organization{} = organization -> {:ok, organization}
      nil -> {:error, :organization_not_found}
    end
  end

  @doc """
  Registers a new organization.
  """
  @spec register_organization(binary(), binary()) ::
          {:ok, Organization.t()} | {:error, :handle_name_taken}
  def register_organization(handle_name, owner_user_id) do
    Repo.transact(fn ->
      with :ok <- ReservedHandleName.ensure_available(handle_name),
           {:ok, organization} <- create_organization(),
           :ok <- set_organization_owner(organization, owner_user_id),
           :ok <- create_handle_name(organization, handle_name) do
        {:ok, organization}
      else
        {:error, :handle_name_reserved} -> {:error, :handle_name_taken}
        reply -> reply
      end
    end)
  end

  defp create_organization() do
    {:ok, Repo.insert!(%Organization{})}
  end

  defp set_organization_owner(%Organization{} = organization, owner_user_id) do
    organization
    |> build_assoc(:memberships)
    |> OrganizationMembership.changeset(%{user_id: owner_user_id, role: :owner})
    |> Repo.insert!()

    :ok
  end

  defp create_handle_name(%Organization{} = organization, handle_name) do
    organization
    |> build_assoc(:handle_name)
    |> HandleName.changeset(%{value: handle_name})
    |> Repo.insert()
    |> case do
      {:ok, %HandleName{}} -> :ok
      reply -> reply
    end
  end

  @spec update_display_name(binary(), binary()) ::
          {:ok, Organization.t()} | {:error, :organization_not_found | Changeset.t()}
  def update_display_name(organization_id, display_name) do
    case get_by_id(organization_id) do
      {:ok, %Organization{} = organization} ->
        organization
        |> Organization.update_display_name(%{display_name: display_name})
        |> Repo.update()

      reply ->
        reply
    end
  end

  @spec update_handle_name(binary(), binary()) ::
          {:ok, Organization.t()} | {:error, :organization_not_found | Changeset.t()}
  def update_handle_name(organization_id, handle_name) do
    case get_by_id(organization_id, [:handle_name]) do
      {:ok, %Organization{} = organization} ->
        organization
        |> Organization.update_handle_name(%{handle_name: handle_name})
        |> Repo.update()

      reply ->
        reply
    end
  end

  @spec update_bio(binary(), binary()) ::
          {:ok, Organization.t()} | {:error, :organization_not_found | Changeset.t()}
  def update_bio(organization_id, bio) do
    case get_by_id(organization_id) do
      {:ok, %Organization{} = organization} ->
        organization
        |> Organization.update_bio(%{bio: bio})
        |> Repo.update()

      reply ->
        reply
    end
  end

  @doc """
  Invites a user to join the organization by email address. If the email address
  is associated with a user, invite will be sent to the user.
  """
  @spec invite_member_by_email_address(
          binary(),
          binary(),
          OrganizationInvite.Role.t()
        ) ::
          {:ok, OrganizationInvite.t()}
          | {:error,
             :already_an_organization_member
             | :exceeded_max_organization_membership_limit
             | :organization_not_found
             | :user_not_found}
  def invite_member_by_email_address(organization_id, email_address, role) do
    Repo.transact(fn ->
      case Repo.get_by(User, email_address: email_address) do
        nil ->
          with {:ok, organization} <- get_by_id(organization_id),
               {:ok, invite} <-
                 create_invite_for_email_address(organization, email_address, role),
               :ok <- SendOrganizationInviteEmail.schedule(email_address, invite),
               do: {:ok, invite}

        %User{} = user ->
          invite_member_by_user_id(organization_id, user.id, role)
      end
    end)
  end

  defp create_invite_for_email_address(%Organization{} = organization, email_address, role) do
    organization = Repo.preload(organization, [:invites])

    organization.invites
    |> Enum.split_with(&(&1.email_address == email_address))
    |> case do
      {[], _other_invites} ->
        updated_organization =
          organization
          |> Organization.create_invite(%{email_address: email_address, role: role})
          |> Repo.update!()

        {:ok, Enum.find(updated_organization.invites, &(&1.email_address == email_address))}

      {[invite], _other_invites} ->
        {:ok, Map.put(invite, :new?, false)}
    end
  end

  @doc """
  Invites a user to join the organization by user ID.
  """
  @spec invite_member_by_user_id(binary(), binary(), OrganizationInvite.Role.t()) ::
          {:ok, OrganizationInvite.t()}
          | {:error,
             :user_not_found
             | :organization_not_found
             | :already_an_organization_member}
  def invite_member_by_user_id(organization_id, new_member_user_id, role) do
    Repo.transact(fn ->
      with {:ok, user} <- Users.get_by_id(new_member_user_id),
           {:ok, organization} <- get_by_id(organization_id),
           :ok <- check_has_membership(organization, new_member_user_id),
           {:ok, invite} <- create_invite_for_user(organization, new_member_user_id, role),
           :ok <- SendOrganizationInviteEmail.schedule(user.email_address, invite),
           do: {:ok, invite}
    end)
  end

  defp check_has_membership(organization, user_id) do
    case get_membership(organization, user_id) do
      {:error, :organization_membership_not_found} -> :ok
      {:ok, %OrganizationMembership{}} -> {:error, :already_an_organization_member}
    end
  end

  defp create_invite_for_user(%Organization{} = organization, user_id, role) do
    organization = Repo.preload(organization, [:invites])

    organization.invites
    |> Enum.split_with(&(&1.user_id == user_id))
    |> case do
      {[], _other_invites} ->
        updated_organization =
          organization
          |> Organization.create_invite(%{user_id: user_id, role: role})
          |> Repo.update!()

        {:ok, Enum.find(updated_organization.invites, &(&1.user_id == user_id))}

      {[invite], _other_invites} ->
        {:ok, Map.put(invite, :new?, false)}
    end
  end

  @spec accept_invite(binary(), binary()) ::
          {:ok, OrganizationMembership.t()}
          | {:error,
             :user_not_found
             | :organization_not_found}
  def accept_invite(organization_id, user_id) do
    Repo.transact(fn ->
      # TODO enforce max membership per org?
      with {:ok, _user} <- Users.get_by_id(user_id),
           {:ok, organization} <- get_by_id(organization_id),
           {:ok, invite} <- remove_invite(organization, user_id),
           {:ok, membership} <- create_membership(organization, user_id, invite.role),
           do: {:ok, membership}
    end)
  end

  @spec remove_invite(binary() | Organization.t(), binary()) ::
          {:ok, OrganizationInvite.t()}
          | {:error, :organization_not_found | :organization_invite_not_found}
  def remove_invite(organization_id, user_id) when is_binary(organization_id) do
    with {:ok, organization} <- get_by_id(organization_id),
         do: remove_invite(organization, user_id)
  end

  def remove_invite(%Organization{} = organization, user_id) do
    organization = Repo.preload(organization, [:invites])

    case Enum.find(organization.invites, &(&1.user_id == user_id)) do
      %OrganizationInvite{} = invite ->
        organization
        |> Organization.remove_invite(invite.id)
        |> Repo.update!()

        {:ok, invite}

      nil ->
        {:error, :organization_invite_not_found}
    end
  end

  @spec remove_member(binary(), binary()) ::
          {:ok, OrganizationMembership.t()}
          | {:error, :organization_membership_not_found | :organization_not_found}
  def remove_member(organization_id, user_id) do
    with {:ok, organization} <- get_by_id(organization_id),
         :ok <- enforce_min_one_owner(organization, user_id) do
      organization = Repo.preload(organization, [:memberships])

      case Enum.find(organization.memberships, &(&1.user_id == user_id)) do
        %OrganizationMembership{} = membership ->
          organization
          |> Organization.remove_membership(membership.id)
          |> Repo.update!()

          {:ok, membership}

        nil ->
          {:error, :organization_membership_not_found}
      end
    end
  end

  @spec change_member_role(binary(), binary(), OrganizationMembership.Role.t()) ::
          {:ok, OrganizationMembership.t()}
          | {:error,
             :organization_not_found
             | :organization_membership_not_found
             | :cannot_change_last_owner_role}
  def change_member_role(organization_id, user_id, new_role) do
    with {:ok, organization} <- get_by_id(organization_id),
         :ok <- enforce_min_one_owner(organization, user_id) do
      organization = Repo.preload(organization, [:memberships])

      case Enum.find(organization.memberships, &(&1.user_id == user_id)) do
        %OrganizationMembership{} = membership ->
          updated_organization =
            organization
            |> Organization.change_membership_role(membership.id, new_role)
            |> Repo.update!()

          {:ok, Enum.find(updated_organization.memberships, &(&1.id == membership.id))}

        nil ->
          {:error, :organization_membership_not_found}
      end
    else
      {:error, :must_have_at_least_one_owner} -> {:error, :cannot_change_last_owner_role}
      reply -> reply
    end
  end

  defp get_membership(%Organization{} = organization, user_id) do
    organization = Repo.preload(organization, [:memberships])

    case Enum.find(organization.memberships, &(&1.user_id == user_id)) do
      %OrganizationMembership{} = membership -> {:ok, membership}
      nil -> {:error, :organization_membership_not_found}
    end
  end

  defp create_membership(%Organization{} = organization, user_id, role) do
    organization = Repo.preload(organization, [:memberships])

    organization.memberships
    |> Enum.split_with(&(&1.user_id == user_id))
    |> case do
      {[], _other_memberships} ->
        updated_organization =
          organization
          |> Organization.create_membership(%{user_id: user_id, role: role})
          |> Repo.update!()

        {:ok, get_membership(updated_organization, user_id)}

      {[membership], _other_memberships} ->
        {:ok, membership}
    end
  end

  defp enforce_min_one_owner(%Organization{} = organization, excluded_user_id) do
    organization = Repo.preload(organization, [:memberships])

    organization.memberships
    |> Enum.reject(&(&1.user_id == excluded_user_id))
    |> Enum.find(&(&1.role == :owner))
    |> case do
      %OrganizationMembership{} -> :ok
      nil -> {:error, :must_have_at_least_one_owner}
    end
  end
end
