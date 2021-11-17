defmodule API.OrganizationMembership do
  @moduledoc false

  use API, :model

  defenum(Role, owner: 0, member: 1)
  defenum(Visibility, public: 0, private: 1)

  schema "organization_membership" do
    belongs_to :organization, API.Organization
    belongs_to :user, API.User
    field :role, Role
    field :visibility, Visibility, default: :public
    timestamps()
  end

  @spec changeset(t(), data) :: Ecto.Changeset.t()
        when data: %{
               organization_id: binary(),
               user_id: binary(),
               role: __MODULE__.Role.t()
             }
  def changeset(%__MODULE__{} = org_member, data) do
    params = ~w(organization_id user_id role)a

    org_member
    |> cast(data, params)
    |> validate_required(params)
    |> validate_enum(:role)
    |> foreign_key_constraint(:organization_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:user_id, :organization_id])
  end
end
