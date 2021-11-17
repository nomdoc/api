defmodule API.OrganizationInviteTest do
  @moduledoc false

  use API.DataCase, async: true

  alias API.OrganizationInvite

  describe "changeset/2" do
    test "requires either user ID or email address." do
      assert %Ecto.Changeset{valid?: true} =
               OrganizationInvite.changeset(%OrganizationInvite{}, %{
                 user_id: Faker.UUID.v4(),
                 organization_id: Faker.UUID.v4(),
                 role: :member
               })

      assert %Ecto.Changeset{valid?: true} =
               OrganizationInvite.changeset(%OrganizationInvite{}, %{
                 email_address: Faker.Internet.email(),
                 organization_id: Faker.UUID.v4(),
                 role: :member
               })

      changeset =
        OrganizationInvite.changeset(%OrganizationInvite{}, %{
          organization_id: Faker.UUID.v4(),
          role: :member
        })

      refute changeset.valid?

      assert errors_on(changeset)[:user_id] == [
               "One of these fields must be present: [:user_id, :email_address]"
             ]
    end

    test "validates user ID and organization ID are unique." do
      invite = insert(:user_organization_invite)

      assert {:error, %Changeset{} = changeset} =
               OrganizationInvite.changeset(%OrganizationInvite{}, %{
                 user_id: invite.user.id,
                 organization_id: invite.organization.id,
                 role: :member
               })
               |> Repo.insert()

      assert errors_on(changeset)[:user_id] == ["has already been taken"]
    end

    test "validates email address and organization ID are unique." do
      invite = insert(:organization_invite)

      assert {:error, %Changeset{} = changeset} =
               OrganizationInvite.changeset(%OrganizationInvite{}, %{
                 email_address: invite.email_address,
                 organization_id: invite.organization.id,
                 role: :member
               })
               |> Repo.insert()

      assert errors_on(changeset)[:email_address] == ["has already been taken"]
    end
  end
end
