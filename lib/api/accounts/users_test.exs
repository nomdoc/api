defmodule API.UsersTest do
  @moduledoc false

  use API.DataCase, async: true

  alias API.User
  alias API.Users

  describe "register_user_with_password/2" do
    test "creates a user if not exists." do
      assert {:ok, %User{} = user} =
               Users.register_user_with_password(Faker.Internet.email(), Faker.String.base64())

      user = Repo.preload(user, [:handle_name, :refresh_tokens])

      assert user.new?
      refute user.email_address_verified?
      assert is_binary(user.handle_name.value)
      assert Enum.empty?(user.refresh_tokens)
    end

    test "returns the user if user has already been created." do
      email_address = Faker.Internet.email()
      password = Faker.String.base64()

      assert {:ok, %User{id: user_id}} =
               Users.register_user_with_password(email_address, password)

      assert {:ok, %User{id: ^user_id, new?: false}} =
               Users.register_user_with_password(email_address, password)
    end
  end

  describe "register_user_with_google_account/2" do
    test "creates a user if not exists." do
      email_address = Faker.Internet.email()
      google_account_id = Faker.String.base64()

      assert {:ok, %User{} = user} =
               Users.register_user_with_google_account(email_address, google_account_id)

      user = Repo.preload(user, [:handle_name, :refresh_tokens])

      assert user.new?
      assert user.email_address_verified?
      assert is_binary(user.handle_name.value)
      assert Enum.empty?(user.refresh_tokens)
    end

    test "returns the user if a user with Google Account ID already exists." do
      google_account_id = Faker.String.base64()

      assert {:ok, %User{id: user_id}} =
               Users.register_user_with_google_account(Faker.Internet.email(), google_account_id)

      assert {:ok, %User{id: ^user_id, new?: false}} =
               Users.register_user_with_google_account(Faker.Internet.email(), google_account_id)
    end

    test "returns the user if a user with email address already exists." do
      email_address = Faker.Internet.email()

      assert {:ok, %User{id: user_id}} =
               Users.register_user_with_google_account(email_address, Faker.String.base64())

      assert {:ok, %User{id: ^user_id, new?: false}} =
               Users.register_user_with_google_account(email_address, Faker.String.base64())
    end
  end

  # TODO test get_user/2

  describe "update_display_name/2" do
    test "updates user's display name." do
      user = insert(:user)

      assert {:ok, %User{} = updated_user} = Users.update_display_name(user.id, "Meow")
      assert updated_user.display_name == "Meow"
    end
  end

  describe "update_handle_name/2" do
    test "updates user's handle name." do
      user = insert(:user)

      assert {:ok, %User{} = updated_user} = Users.update_handle_name(user.id, "meow")
      assert updated_user.handle_name.value == "meow"
    end
  end

  # TODO test update_bio/2
end
