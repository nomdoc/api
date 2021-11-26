defmodule API.Auth do
  @moduledoc false

  use API, :context

  alias API.AuthTokens
  alias API.RefreshToken
  alias API.User
  alias API.Users
  alias API.Utils

  @spec register_with_password(binary(), binary()) ::
          {:ok, User.t()} | {:error, :user_already_registered}
  def register_with_password(email_address, password) do
    case Repo.get_by(User, email_address: email_address) do
      %User{} ->
        {:error, :user_already_registered}

      nil ->
        Users.register_user_with_password(email_address, password)
    end
  end

  @spec verify_password(binary(), binary()) ::
          {:ok, AuthTokens.t()}
          | {:error,
             :invalid_password
             | :user_not_registered}
  def verify_password(email_address, password) do
    case Repo.get_by(User, email_address: email_address) do
      nil ->
        {:error, :user_not_registered}

      %User{} = user ->
        with :ok <- check_password(user, password),
             {:ok, refresh_token} <- AuthTokens.create_refresh_token(user),
             {:ok, access_token} <- AuthTokens.create_access_token(user.id),
             {:ok, access_token_claims} <- AuthTokens.peek_access_token(access_token),
             do:
               {:ok,
                %AuthTokens{
                  refresh_token: refresh_token.id,
                  access_token: access_token,
                  access_token_expired_at: access_token_claims["exp"]
                }}
    end
  end

  defp check_password(%User{} = user, password) do
    case Argon2.check_pass(user, password) do
      {:ok, _user} -> :ok
      _reply -> {:error, :invalid_password}
    end
  end

  @doc """
  Exchanges a valid refresh token for a new pair of refresh and access tokens.
  """
  @spec exchange_refresh_token(binary()) ::
          {:ok, AuthTokens.t()} | {:error, :invalid_refresh_token}
  def exchange_refresh_token(refresh_token_id) do
    with {:ok, refresh_token} <- get_and_validate_refresh_token(refresh_token_id),
         :ok <- AuthTokens.invalidate_refresh_token(refresh_token),
         {:ok, new_refresh_token} <- AuthTokens.renew_refresh_token(refresh_token),
         {:ok, access_token} <- AuthTokens.create_access_token(new_refresh_token.user_id),
         {:ok, access_token_claims} <- AuthTokens.peek_access_token(access_token) do
      {:ok,
       %AuthTokens{
         refresh_token: new_refresh_token.id,
         access_token: access_token,
         access_token_expired_at: access_token_claims["exp"]
       }}
    else
      _reply -> {:error, :invalid_refresh_token}
    end
  end

  defp get_and_validate_refresh_token(refresh_token_id) do
    case Repo.get(RefreshToken, refresh_token_id) do
      %RefreshToken{status: :valid} = refresh_token ->
        if Utils.expired?(refresh_token.absolute_timeout_at) do
          :ok = AuthTokens.invalidate_refresh_token(refresh_token)

          {:error, :refresh_token_timed_out}
        else
          {:ok, refresh_token}
        end

      %RefreshToken{} ->
        Logger.error("Refresh token #{refresh_token_id} is reused.")
        {:error, :refresh_token_reuse_detected}

      nil ->
        Logger.error("Refresh token #{refresh_token_id} is not known.")
        {:error, :refresh_token_fixation_detected}
    end
  end

  @doc """
  Verifies an access token and fetches the user.
  """
  @spec debug_access_token(binary()) :: {:ok, User.t()} | {:error, :invalid_access_token}
  def debug_access_token(access_token) do
    with {:ok, claims} <- AuthTokens.verify_access_token(access_token) do
      user_id = Map.get(claims, "sub") || raise KeyError, key: "sub", term: claims

      case Repo.get(User, user_id) do
        %User{} = user -> {:ok, user}
        nil -> {:error, :invalid_access_token}
      end
    end
  end

  @doc """
  Invalidates refresh token.
  """
  @spec logout(binary()) :: :ok
  def logout(refresh_token_id) do
    Repo.update_all(
      RefreshToken.get_by_id(refresh_token_id),
      set: [status: :invalidated, updated_at: DateTime.utc_now()]
    )

    :ok
  end
end
