defmodule API.AuthTest do
  @moduledoc false

  use API.DataCase, async: true

  alias API.Auth
  alias API.AuthTokens
  alias API.RefreshToken
  alias API.User

  describe "login_with_token/1" do
    test "creates a new user, if not registered, and initiates a login." do
      # TODO assert Mailer stub

      assert {:ok, %User{new?: true} = user} = Auth.login_with_token("kokjinsam@gmail.com")

      user = Repo.preload(user, [:handle_name, :logins, :organization_invites], force: true)

      assert length(user.logins) == 1
      assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :mailer)
    end
  end

  describe "verify_login_token/1" do
    test "validates login token and returns auth tokens." do
      user = insert(:user)
      login = insert(:login, user: user)

      assert {:ok, %AuthTokens{} = auth_tokens} = Auth.verify_login_token(login.token)
      assert is_binary(auth_tokens.refresh_token)
      assert is_binary(auth_tokens.access_token)
      assert is_number(auth_tokens.access_token_expired_at)
    end
  end

  describe "verify_google_id_token/1" do
    test "validates Google ID token, creates a new user if not registered and returns auth tokens." do
      google_email_address = "example@gmail.com"

      expect(API.GoogleAuthMock, :verify_id_token, 1, fn _token ->
        {:ok, build(:google_user, email_address: google_email_address)}
      end)

      assert {:ok, %AuthTokens{} = auth_tokens} =
               Auth.verify_google_id_token(Faker.String.base64())

      assert is_binary(auth_tokens.refresh_token)
      assert is_binary(auth_tokens.access_token)
      assert is_number(auth_tokens.access_token_expired_at)

      assert %User{} =
               user =
               Repo.get_by(User, email_address: google_email_address)
               |> Repo.preload([:handle_name, :logins, :organization_invites])

      assert is_binary(user.handle_name.value)
      assert Enum.empty?(user.logins)
      assert Enum.empty?(user.organization_invites)
    end

    test "throws error if Google User's email address is not verified" do
      expect(API.GoogleAuthMock, :verify_id_token, 1, fn _token ->
        {:ok, build(:google_user, email_address_verified: false)}
      end)

      assert {:error, :google_email_not_verified} =
               Auth.verify_google_id_token(Faker.String.base64())
    end
  end

  describe "exchange_refresh_token/1" do
    test "invalidates the refresh token and issues a new set of auth tokens." do
      refresh_token = insert(:refresh_token)

      assert {:ok, %AuthTokens{} = auth_tokens} = Auth.exchange_refresh_token(refresh_token.id)
      assert is_binary(auth_tokens.refresh_token)
      assert auth_tokens.refresh_token != refresh_token.id
      assert is_binary(auth_tokens.access_token)
      assert is_number(auth_tokens.access_token_expired_at)

      old_refresh_token = Repo.get(RefreshToken, refresh_token.id)

      assert old_refresh_token.status == :invalidated
    end

    test "throws error if refresh token is not valid." do
      refresh_token = insert(:refresh_token, status: :invalidated)

      assert {:error, :invalid_refresh_token} = Auth.exchange_refresh_token(refresh_token.id)
    end
  end

  describe "logout/1" do
    test "invalidates the refresh token." do
      refresh_token = insert(:refresh_token)

      assert :ok = Auth.logout(refresh_token.id)

      invalidated_refresh_token = Repo.get(RefreshToken, refresh_token.id)

      assert invalidated_refresh_token.status == :invalidated
    end
  end
end
