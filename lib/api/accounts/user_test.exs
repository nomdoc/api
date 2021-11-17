defmodule API.UserTest do
  @moduledoc false

  use API.DataCase, async: true

  alias API.User

  describe "changeset/2" do
    test "builds a user correctly." do
      changeset =
        User.changeset(%User{}, %{id: Ecto.UUID.generate(), email_address: "samkj.ks@gmail.com"})

      assert changeset.valid?
    end

    test "validates email address is unique." do
      user = insert(:user)

      assert {:error, %Changeset{} = changeset} =
               User.changeset(%User{}, %{
                 id: Ecto.UUID.generate(),
                 email_address: user.email_address
               })
               |> Repo.insert()

      assert errors_on(changeset)[:email_address] == ["has already been taken"]
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
end
