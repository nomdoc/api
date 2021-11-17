defmodule API.Login do
  @moduledoc false

  use API, :model
  alias API.User

  defenum(Status, pending: 0, completed: 1)

  schema "login" do
    belongs_to :user, User
    field :status, Status, default: :pending
    field :token, :string, virtual: true
    field :token_hash, :string
    field :completed_at, :utc_datetime_usec
    field :expired_at, :utc_datetime_usec
    timestamps()
  end

  @spec changeset(t(), data) :: Changeset.t() when data: %{user_id: binary()}
  def changeset(%__MODULE__{} = login, data) do
    params = ~w(user_id)a
    token = generate_token()
    token_hash = hash_token(token)
    expired_at = generate_expired_at()

    login
    |> cast(data, params)
    |> validate_required(params)
    |> foreign_key_constraint(:user_id)
    |> put_change(:token, token)
    |> put_change(:token_hash, token_hash)
    |> put_change(:expired_at, expired_at)
  end

  @spec generate_token() :: binary()
  def generate_token() do
    UUID.uuid4(:hex)
  end

  @spec hash_token(binary()) :: binary()
  def hash_token(token) do
    token_hash_key = Application.fetch_env!(:api, API.Accounts)[:login_token_hash_key]

    API.Utils.hmac(token_hash_key, token)
  end

  @spec generate_expired_at() :: DateTime.t()
  def generate_expired_at() do
    ttl = Application.fetch_env!(:api, API.Accounts)[:login_ttl]

    DateTime.add(DateTime.utc_now(), ttl)
  end

  @spec mark_completed(t()) :: Changeset.t()
  def mark_completed(%__MODULE__{} = login) do
    change(login, status: :completed, completed_at: DateTime.utc_now())
  end
end
