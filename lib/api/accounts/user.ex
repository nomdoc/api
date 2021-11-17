defmodule API.User do
  @moduledoc false

  use API, :model

  defenum(Role, superuser: 0, admin: 1, user: 3)
  defenum(Gender, unspecified: 0, male: 1, female: 2)

  schema "user" do
    field :role, Role, default: :user
    field :new?, :boolean, virtual: true, default: false

    field :email_address, :string
    has_one :handle_name, API.HandleName, on_replace: :update
    field :display_name, :string
    field :bio, :string
    field :gender, Gender, default: :unspecified

    has_many :logins, API.Login
    has_many :refresh_tokens, API.RefreshToken
    has_many :organization_invites, API.OrganizationInvite
    has_many :organization_memberships, API.OrganizationMembership

    timestamps()
  end

  @spec changeset(t(), data) :: Changeset.t() when data: %{id: binary(), email_address: binary()}
  def changeset(%__MODULE__{} = user, data) do
    params = ~w(id email_address)a

    user
    |> cast(data, params)
    |> validate_required(params)
    |> unique_constraint(:email_address)
  end

  @spec update_display_name(t(), data) :: Changeset.t() when data: %{display_name: binary()}
  def update_display_name(%__MODULE__{} = user, data) do
    params = ~w(display_name)a

    user
    |> cast(data, params)
    |> validate_required(params)
  end

  @spec update_bio(t(), data) :: Changeset.t() when data: %{bio: binary()}
  def update_bio(%__MODULE__{} = user, data) do
    params = ~w(bio)a

    user
    |> cast(data, params)
    |> validate_required(params)
  end

  @spec update_email_address(t(), data) :: Changeset.t() when data: %{email_address: binary()}
  def update_email_address(%__MODULE__{} = user, data) do
    params = ~w(email_address)a

    user
    |> cast(data, params)
    |> validate_required(params)
    |> unique_constraint(:email_address)
  end

  @spec update_handle_name(t(), data) :: Changeset.t() when data: %{handle_name: binary()}
  def update_handle_name(%__MODULE__{} = user, data) do
    data = Map.put(data, :handle_name, %{value: data.handle_name})

    user
    |> cast(data, [])
    |> cast_assoc(:handle_name)
  end
end
