defmodule API.OrganizationsTest do
  @moduledoc false

  use API.DataCase, async: true

  alias API.Organization
  alias API.OrganizationInvite
  alias API.Organizations

  describe "register_organization/2" do
    test "creates an organization." do
      owner_user = insert(:user)

      assert {:ok, %Organization{} = organization} =
               Organizations.register_organization("meow", owner_user.id)

      organization = Repo.preload(organization, [:handle_name, :invites, :memberships])

      assert is_nil(organization.display_name)
      assert is_nil(organization.bio)
      assert is_nil(organization.email_address)
      assert organization.handle_name.value == "meow"
      assert Enum.empty?(organization.invites)
      assert length(organization.memberships) == 1

      owner_membership = hd(organization.memberships)

      assert owner_membership.user_id == owner_user.id
      assert owner_membership.role == :owner
      assert owner_membership.visibility == :public
    end
  end

  describe "invite_member_by_email_address/3" do
    test "sends an organization invite to the email address." do
      # TODO assert Mailer stub

      organization = insert(:organization)
      email_address = Faker.Internet.email()

      assert {:ok,
              %OrganizationInvite{id: invite_id, email_address: ^email_address, role: :member}} =
               Organizations.invite_member_by_email_address(
                 organization.id,
                 email_address,
                 :member
               )

      assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :mailer)

      updated_organization = Repo.preload(organization, [:invites])

      assert length(updated_organization.invites) == 1
      assert %OrganizationInvite{id: ^invite_id} = hd(updated_organization.invites)
    end

    test "attaches the organization invite to the user who owns the email address" do
      organization = insert(:organization)
      %API.User{id: user_id} = user = insert(:user)

      assert {:ok, %OrganizationInvite{id: invite_id, user_id: ^user_id}} =
               Organizations.invite_member_by_email_address(
                 organization.id,
                 user.email_address,
                 :member
               )

      updated_organization = Repo.preload(organization, [:invites])

      assert length(updated_organization.invites) == 1
      assert %OrganizationInvite{id: ^invite_id} = hd(updated_organization.invites)
    end
  end

  describe "invite_member_by_user_id/3" do
    test "sends an organization invite to the user." do
      %API.Organization{id: organization_id} = organization = insert(:organization)
      %API.User{id: user_id} = insert(:user)

      assert {:ok,
              %OrganizationInvite{
                id: invite_id,
                organization_id: ^organization_id,
                user_id: ^user_id,
                role: :member
              }} = Organizations.invite_member_by_user_id(organization_id, user_id, :member)

      assert %{success: 1, failure: 0} = Oban.drain_queue(queue: :mailer)

      updated_organization = Repo.preload(organization, [:invites], force: true)

      assert length(updated_organization.invites) == 1
      assert %OrganizationInvite{id: ^invite_id} = hd(updated_organization.invites)
    end

    test "throws error if user does not exist" do
      organization = insert(:organization)

      assert {:error, :user_not_found} =
               Organizations.invite_member_by_user_id(
                 organization.id,
                 Ecto.UUID.generate(),
                 :member
               )
    end

    test "throws error if organization does not exist" do
      user = insert(:user)

      assert {:error, :organization_not_found} =
               Organizations.invite_member_by_user_id(
                 Ecto.UUID.generate(),
                 user.id,
                 :member
               )
    end

    test "throws error if user is already a member of the organization." do
      user = insert(:user)
      organization = insert(:organization)

      insert(:organization_membership, user: user, organization: organization)

      assert {:error, :already_an_organization_member} =
               Organizations.invite_member_by_user_id(organization.id, user.id, :member)
    end
  end
end
