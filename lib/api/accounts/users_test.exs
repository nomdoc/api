defmodule API.UsersTest do
  @moduledoc false

  use API.DataCase, async: true

  alias API.OrganizationInvite
  alias API.User
  alias API.Users

  describe "get_or_create/1" do
    test "creates a user if not exists." do
      assert {:ok, %User{} = user} = Users.get_or_create("kokjinsam@gmail.com")

      user =
        Repo.preload(user, [
          :handle_name,
          :logins,
          :refresh_tokens,
          :organization_invites,
          :organization_memberships
        ])

      assert user.role == :user
      assert user.new?
      assert is_nil(user.display_name)
      assert is_nil(user.bio)
      assert is_binary(user.handle_name.value)
      assert user.email_address == "kokjinsam@gmail.com"
      assert user.gender == :unspecified
      assert Enum.empty?(user.logins)
      assert Enum.empty?(user.refresh_tokens)
      assert Enum.empty?(user.organization_invites)
      assert Enum.empty?(user.organization_memberships)
    end

    test "claims all organization invites that belong to the user." do
      %OrganizationInvite{id: org_invite_id} = org_invite = insert(:organization_invite)

      assert {:ok, %User{} = user} = Users.get_or_create(org_invite.email_address)

      user = Repo.preload(user, [:organization_invites], force: true)

      assert length(user.organization_invites) == 1
      assert %OrganizationInvite{id: ^org_invite_id} = hd(user.organization_invites)
    end

    test "returns the user if user has already been created." do
      assert {:ok, %User{id: user_id}} = Users.get_or_create("kokjinsam@gmail.com")
      assert {:ok, %User{id: ^user_id, new?: false}} = Users.get_or_create("kokjinsam@gmail.com")
    end
  end

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
end
