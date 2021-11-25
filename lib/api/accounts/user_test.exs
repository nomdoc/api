defmodule API.UserTest do
  @moduledoc false

  use API.DataCase, async: true

  alias API.User

  describe "build_with_password/2" do
    test "builds a user correctly." do
      email_address = Faker.Internet.email()

      changeset =
        User.build_with_password(%User{}, %{
          id: Ecto.UUID.generate(),
          email_address: email_address,
          password: Faker.String.base64()
        })

      assert changeset.valid?

      user = apply_changes(changeset)

      assert user.role == :user
      refute user.new?
      assert user.email_address == email_address
      refute user.email_address_verified?
      assert is_nil(user.password)
      assert is_binary(user.password_hash)
      assert is_nil(user.google_account_id)
      assert is_nil(user.display_name)
      assert is_nil(user.bio)
      assert user.gender == :unspecified
    end

    test "validates email address is unique." do
      user = insert(:user)

      assert {:error, %Changeset{} = changeset} =
               User.build_with_password(%User{}, %{
                 id: Ecto.UUID.generate(),
                 email_address: user.email_address,
                 password: Faker.String.base64()
               })
               |> Repo.insert()

      assert errors_on(changeset)[:email_address] == ["has already been taken"]
    end
  end

  describe "build_with_google_account/2" do
    test "builds a user correctly." do
      email_address = Faker.Internet.email()
      google_account_id = Faker.String.base64()

      changeset =
        User.build_with_google_account(%User{}, %{
          id: Ecto.UUID.generate(),
          email_address: email_address,
          google_account_id: google_account_id
        })

      assert changeset.valid?

      user = apply_changes(changeset)

      assert user.role == :user
      refute user.new?
      assert user.email_address == email_address
      assert user.email_address_verified?
      assert is_nil(user.password)
      assert is_nil(user.password_hash)
      assert is_binary(user.google_account_id)
      assert is_nil(user.display_name)
      assert is_nil(user.bio)
      assert user.gender == :unspecified
    end

    test "validates email address is unique." do
      user = insert(:user_with_google_account)

      assert {:error, %Changeset{} = changeset} =
               User.build_with_google_account(%User{}, %{
                 id: Ecto.UUID.generate(),
                 email_address: user.email_address,
                 google_account_id: Faker.String.base64()
               })
               |> Repo.insert()

      assert errors_on(changeset)[:email_address] == ["has already been taken"]
    end

    test "validates Google Account ID is unique." do
      user = insert(:user_with_google_account)

      assert {:error, %Changeset{} = changeset} =
               User.build_with_google_account(%User{}, %{
                 id: Ecto.UUID.generate(),
                 email_address: Faker.Internet.email(),
                 google_account_id: user.google_account_id
               })
               |> Repo.insert()

      assert errors_on(changeset)[:google_account_id] == ["has already been taken"]
    end
  end

  describe "update_email_address/2" do
    test "validates email address is unique." do
      insert(:user, email_address: "example@gmail.com")

      user2 = insert(:user, email_address: "example2@gmail.com")

      assert {:error, %Changeset{} = changeset} =
               User.update_email_address(user2, %{email_address: "example@gmail.com"})
               |> Repo.update()

      assert errors_on(changeset)[:email_address] == ["has already been taken"]
    end
  end

  describe "update_handle_name/2" do
    test "updates user's handle name." do
      user = insert(:user)

      assert {:ok, %User{} = updated_user} =
               User.update_handle_name(user, %{handle_name: "meow"})
               |> Repo.update()

      assert updated_user.handle_name.value == "meow"
    end
  end

  # TODO test update_display_name/2
  # TODO test update_bio/2
end
