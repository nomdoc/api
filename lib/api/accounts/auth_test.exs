defmodule API.AuthTest do
  @moduledoc false

  use API.DataCase, async: true

  alias API.Auth
  alias API.AuthTokens
  alias API.RefreshToken
  alias API.User

  describe "register_with_password/2" do
    test "successfully registers the user" do
      assert {:ok, %User{}} =
               Auth.register_with_password(Faker.Internet.email(), Faker.String.base64())
    end

    test "throws error if user already registered with a Google Account." do
      user = insert(:user_with_google_account)

      assert {:error, :user_registered_with_google_account} =
               Auth.register_with_password(user.email_address, Faker.String.base64())
    end

    test "throws error if user already registered." do
      user = insert(:user)

      assert {:error, :user_already_registered} =
               Auth.register_with_password(user.email_address, Faker.String.base64())
    end
  end

  describe "verify_password/2" do
    test "validates the password and returns auth tokens." do
      user = insert(:user)

      assert {:ok, %AuthTokens{}} = Auth.verify_password(user.email_address, user.password)
    end

    test "throws error if password is invalid." do
      user = insert(:user)

      assert {:error, :invalid_password} =
               Auth.verify_password(user.email_address, Faker.String.base64())
    end

    test "throws error if user registered with a Google Account." do
      user = insert(:user_with_google_account)

      assert {:error, :user_registered_with_google_account} =
               Auth.verify_password(user.email_address, Faker.String.base64())
    end

    test "throws error if user is not registered." do
      assert {:error, :user_not_registered} =
               Auth.verify_password(Faker.Internet.email(), Faker.String.base64())
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
    end

    test "throws error if user registered with password." do
      user = insert(:user)

      expect(API.GoogleAuthMock, :verify_id_token, 1, fn _token ->
        {:ok, build(:google_user, email_address: user.email_address)}
      end)

      assert {:error, :user_registered_with_password} =
               Auth.verify_google_id_token(Faker.String.base64())
    end

    test "throws error if Google User's email address is not verified" do
      expect(API.GoogleAuthMock, :verify_id_token, 1, fn _token ->
        {:ok, build(:google_user, email_address_verified?: false)}
      end)

      assert {:error, :google_email_address_not_verified} =
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
