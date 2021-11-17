defmodule API.RefreshToken do
  @moduledoc false

  use API, :model
  alias API.User

  defenum(Status, valid: 0, invalidated: 1)

  schema "refresh_token" do
    belongs_to :user, User
    field :status, Status, default: :valid
    field :absolute_timeout_at, :utc_datetime_usec
    timestamps()
  end

  @spec changeset(t(), data) :: Ecto.Changeset.t() when data: %{user_id: binary()}
  def changeset(%__MODULE__{} = refresh_token, data) do
    params = ~w(user_id)a

    refresh_token
    |> cast(data, params)
    |> validate_required(params)
    |> foreign_key_constraint(:user_id)
    |> put_change(:absolute_timeout_at, generate_absolute_timeout_at())
  end

  @spec renew(t(), t()) :: Changeset.t()
  def renew(%__MODULE__{} = refresh_token, old_refresh_token) do
    change(refresh_token,
      user_id: old_refresh_token.user_id,
      absolute_timeout_at: old_refresh_token.absolute_timeout_at
    )
  end

  @spec generate_absolute_timeout_at() :: DateTime.t()
  def generate_absolute_timeout_at() do
    absolute_timeout = Application.fetch_env!(:api, API.Accounts)[:refresh_token_absolute_timeout]
    current_dt = DateTime.utc_now()

    DateTime.add(current_dt, absolute_timeout)
  end

  @spec invalidate(t()) :: Changeset.t()
  def invalidate(%__MODULE__{} = refresh_token) do
    change(refresh_token, status: :invalidated)
  end

  @spec get_by_id(any) :: Ecto.Query.t()
  def get_by_id(id) do
    from rt in __MODULE__, where: rt.id == ^id
  end
end
