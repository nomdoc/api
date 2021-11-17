defmodule API.Auth do
  @moduledoc false

  use API, :context

  alias API.AccessToken
  alias API.AuthTokens
  alias API.GoogleAuth
  alias API.GoogleUser
  alias API.Login
  alias API.RefreshToken
  alias API.User
  alias API.Users
  alias API.Utils
  alias API.Workers.SendLoginTokenEmail

  @doc """
  Initiates a login. An email that contains the login token will be sent to the
  email address. Login token can be verified using
  `&API.Auth.verify_login_token/1`.
  """
  @spec login_with_token(binary()) :: {:ok, User.t()} | {:error, :login_failed}
  def login_with_token(email_address) do
    Repo.transact(fn ->
      with {:ok, user} <- Users.get_or_create(email_address),
           {:ok, login} <- create_login(user),
           :ok <- SendLoginTokenEmail.schedule(email_address, login) do
        {:ok, user}
      else
        _reply -> {:error, :login_failed}
      end
    end)
  end

  defp create_login(%User{} = user) do
    %Login{}
    |> Login.changeset(%{user_id: user.id})
    |> Repo.insert()
  end

  @doc """
  Verifies login token.
  """
  @spec verify_login_token(binary()) :: {:ok, AuthTokens.t()} | {:error, :login_failed}
  def verify_login_token(token) do
    with {:ok, login} <- get_login_by_token(token),
         :ok <- enforce_login_pending(login),
         {:ok, login} <- mark_login_completed(login),
         user <- Repo.get!(User, login.user_id),
         {:ok, refresh_token} <- create_refresh_token(user),
         {:ok, access_token} <- AccessToken.new(user.id),
         {:ok, access_token_claims} <- AccessToken.peek_claims(access_token) do
      {:ok,
       %AuthTokens{
         refresh_token: refresh_token.id,
         access_token: access_token,
         access_token_expired_at: access_token_claims["exp"]
       }}
    else
      _reply -> {:error, :login_failed}
    end
  end

  defp get_login_by_token(token) do
    token_hash = Login.hash_token(token)

    case Repo.get_by(Login, token_hash: token_hash) do
      %Login{} = login -> {:ok, login}
      _reply -> {:error, :login_not_found}
    end
  end

  defp enforce_login_pending(%Login{} = login) do
    case login do
      %Login{status: :pending} -> :ok
      _reply -> {:error, :invalid_login}
    end
  end

  defp mark_login_completed(%Login{} = login) do
    updated_login =
      login
      |> Login.mark_completed()
      |> Repo.update!()

    {:ok, updated_login}
  end

  @doc """
  Verifies Google ID token.
  """
  @spec verify_google_id_token(binary()) ::
          {:ok, AuthTokens.t()} | {:error, :google_email_not_verified | :login_failed}
  def verify_google_id_token(token) do
    Repo.transact(fn ->
      google_auth_service = GoogleAuth.get_service()

      # vNext track token? limit to one-use only.
      with {:ok, %GoogleUser{email_address_verified: true} = google_user} <-
             google_auth_service.verify_id_token(token),
           {:ok, user} <- Users.get_or_create(google_user.email_address),
           {:ok, refresh_token} <- create_refresh_token(user),
           {:ok, access_token} <- AccessToken.new(user.id),
           {:ok, access_token_claims} <- AccessToken.peek_claims(access_token) do
        {:ok,
         %AuthTokens{
           refresh_token: refresh_token.id,
           access_token: access_token,
           access_token_expired_at: access_token_claims["exp"]
         }}
      else
        {:ok, %GoogleUser{}} -> {:error, :google_email_not_verified}
        _reply -> {:error, :login_failed}
      end
    end)
  end

  @doc """
  Exchanges a valid refresh token for a new pair of refresh and access tokens.
  """
  @spec exchange_refresh_token(binary()) ::
          {:ok, AuthTokens.t()} | {:error, :invalid_refresh_token}
  def exchange_refresh_token(refresh_token_id) do
    with {:ok, refresh_token} <- get_and_validate_refresh_token(refresh_token_id),
         :ok <- invalidate_refresh_token(refresh_token),
         {:ok, new_refresh_token} <- renew_refresh_token(refresh_token),
         {:ok, access_token} <- AccessToken.new(new_refresh_token.user_id),
         {:ok, access_token_claims} <- AccessToken.peek_claims(access_token) do
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
          :ok = invalidate_refresh_token(refresh_token)

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

  defp renew_refresh_token(%RefreshToken{} = refresh_token) do
    new_refresh_token =
      %RefreshToken{}
      |> RefreshToken.renew(refresh_token)
      |> Repo.insert!()

    {:ok, new_refresh_token}
  end

  @doc """
  Verifies an access token and fetches the user.
  """
  @spec debug_access_token(binary()) :: {:ok, User.t()} | {:error, :invalid_access_token}
  def debug_access_token(access_token) do
    with {:ok, claims} <- AccessToken.verify(access_token) do
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

  defp create_refresh_token(%User{id: user_id}) do
    refresh_token =
      %RefreshToken{}
      |> RefreshToken.changeset(%{user_id: user_id})
      |> Repo.insert!()

    {:ok, refresh_token}
  end

  defp invalidate_refresh_token(%RefreshToken{} = refresh_token) do
    refresh_token
    |> RefreshToken.invalidate()
    |> Repo.update!()

    :ok
  end
end
