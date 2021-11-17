defmodule API.Organization do
  @moduledoc false

  use API, :model

  schema "organization" do
    field :display_name, :string
    field :bio, :string
    field :email_address, :string
    has_one :handle_name, API.HandleName, on_replace: :update
    has_many :invites, API.OrganizationInvite, on_replace: :delete
    has_many :memberships, API.OrganizationMembership, on_replace: :delete
    timestamps()
  end

  @spec update_display_name(t(), data) :: Changeset.t() when data: %{display_name: binary()}
  def update_display_name(%__MODULE__{} = organization, data) do
    params = ~w(display_name)a

    organization
    |> cast(data, params)
    |> validate_required(params)
  end

  @spec update_bio(t(), data) :: Changeset.t() when data: %{bio: binary()}
  def update_bio(%__MODULE__{} = organization, data) do
    params = ~w(bio)a

    organization
    |> cast(data, params)
    |> validate_required(params)
  end

  @spec update_email_address(t(), data) :: Changeset.t() when data: %{email_address: binary()}
  def update_email_address(%__MODULE__{} = organization, data) do
    params = ~w(email_address)a

    organization
    |> cast(data, params)
    |> validate_required(params)
  end

  @spec update_handle_name(t(), data) :: Changeset.t()
        when data: %{handle_name: binary()}
  def update_handle_name(%__MODULE__{} = organization, data) do
    data = Map.put(data, :handle_name, %{value: data.handle_name})

    organization
    |> cast(data, [])
    |> cast_assoc(:handle_name)
  end

  @spec create_invite(t(), new_invite) :: Changeset.t()
        when new_invite: %{
               user_id: binary(),
               email_address: binary(),
               role: API.OrganizationInvite.Role.t()
             }
  def create_invite(%__MODULE__{} = organization, new_invite) do
    new_invite = Map.put(new_invite, :organization_id, organization.id)

    data = %{
      invites:
        organization.invites
        |> Enum.map(&convert_struct_to_map/1)
        |> Enum.concat([new_invite])
    }

    organization
    |> cast(data, [])
    |> cast_assoc(:invites)
  end

  @spec remove_invite(t(), binary()) :: Changeset.t()
  def remove_invite(%__MODULE__{} = organization, invite_id) do
    invites =
      organization.invites
      |> Enum.map(&convert_struct_to_map/1)
      |> Enum.reject(&(&1.id == invite_id))

    organization
    |> change()
    |> put_assoc(:invites, invites)
  end

  @spec create_membership(API.Organization.t(), new_membership) :: Changeset.t()
        when new_membership: %{user_id: binary(), role: API.OrganizationMembership.Role.t()}
  def create_membership(%__MODULE__{} = organization, new_membership) do
    new_membership = Map.put(new_membership, :organization_id, organization.id)

    data = %{
      memberships:
        organization.memberships
        |> Enum.map(&convert_struct_to_map/1)
        |> Enum.concat([new_membership])
    }

    organization
    |> cast(data, [])
    |> cast_assoc(:memberships)
  end

  @spec remove_membership(t(), binary()) :: Changeset.t()
  def remove_membership(%__MODULE__{} = organization, membership_id) do
    memberships =
      organization.memberships
      |> Enum.map(&convert_struct_to_map/1)
      |> Enum.reject(&(&1.id == membership_id))

    organization
    |> change()
    |> put_assoc(:memberships, memberships)
  end

  @spec change_membership_role(t(), binary(), API.OrganizationMembership.Role.t()) ::
          Changeset.t()
  def change_membership_role(%__MODULE__{} = organization, membership_id, new_role) do
    data = %{
      memberships:
        organization.memberships
        |> Enum.map(&convert_struct_to_map/1)
        |> Enum.map(fn
          %{id: ^membership_id} = membership -> Map.put(membership, :role, new_role)
          membership -> membership
        end)
    }

    organization
    |> cast(data, [])
    |> cast_assoc(:memberships)
  end
end
