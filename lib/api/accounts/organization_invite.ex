defmodule API.OrganizationInvite do
  @moduledoc false

  use API, :model

  defenum(Role, owner: 0, member: 1)

  schema "organization_invite" do
    belongs_to :organization, API.Organization
    belongs_to :user, API.User
    field :email_address, :string
    field :new?, :boolean, virtual: true, default: true
    field :role, Role
    timestamps()
  end

  @spec changeset(t(), data) :: Ecto.Changeset.t()
        when data: %{
               organization_id: binary(),
               user_id: binary(),
               email_address: binary(),
               role: __MODULE__.Role.t()
             }
  def changeset(%__MODULE__{} = invite, data) do
    params = ~w(organization_id user_id email_address role)a
    required_params = ~w(organization_id role)a
    required_one_of_params = ~w(user_id email_address)a

    invite
    |> cast(data, params)
    |> validate_required(required_params)
    |> validate_required_one_of(required_one_of_params)
    |> validate_enum(:role)
    |> foreign_key_constraint(:organization_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:user_id, :organization_id])
    |> unique_constraint([:email_address, :organization_id])
  end

  @spec get_by_email_address(binary()) :: Ecto.Query.t()
  def get_by_email_address(email_address) do
    from oi in __MODULE__, where: oi.email_address == ^email_address
  end
end
