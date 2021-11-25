defmodule API.AuthTokens do
  @moduledoc false

  use TypedStruct
  use Domo

  alias API.AccessToken
  alias API.RefreshToken
  alias API.Repo
  alias API.User

  typedstruct do
    field :refresh_token, binary(), enforce: true
    field :access_token, binary(), enforce: true
    field :access_token_expired_at, binary(), enforce: true
  end

  @spec create_refresh_token(User.t()) :: {:ok, RefreshToken.t()}
  def create_refresh_token(%User{id: user_id}) do
    refresh_token =
      %RefreshToken{}
      |> RefreshToken.changeset(%{user_id: user_id})
      |> Repo.insert!()

    {:ok, refresh_token}
  end

  @spec invalidate_refresh_token(RefreshToken.t()) :: :ok
  def invalidate_refresh_token(%RefreshToken{} = refresh_token) do
    refresh_token
    |> RefreshToken.invalidate()
    |> Repo.update!()

    :ok
  end

  @spec renew_refresh_token(RefreshToken.t()) :: {:ok, any}
  def renew_refresh_token(%RefreshToken{} = refresh_token) do
    new_refresh_token =
      %RefreshToken{}
      |> RefreshToken.renew(refresh_token)
      |> Repo.insert!()

    {:ok, new_refresh_token}
  end

  @spec create_access_token(binary()) :: {:ok, binary()}
  defdelegate create_access_token(user_id), to: AccessToken, as: :new

  @spec verify_access_token(binary()) :: {:ok, Joken.claims()} | {:error, :invalid_access_token}
  defdelegate verify_access_token(access_token), to: AccessToken, as: :verify

  @spec peek_access_token(binary()) :: {:ok, Joken.claims()}
  defdelegate peek_access_token(access_token), to: AccessToken, as: :peek_claims
end
