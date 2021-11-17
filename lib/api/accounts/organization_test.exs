defmodule API.OrganizationTest do
  @moduledoc false

  use API.DataCase, async: true

  alias API.Organization

  describe "update_handle_name/2" do
    test "updates organization's handle name." do
      organization = insert(:organization)

      assert {:ok, %Organization{} = updated_organization} =
               Organization.update_handle_name(organization, %{handle_name: "meow"})
               |> Repo.update()

      updated_organization = Repo.preload(updated_organization, [:handle_name], force: true)

      assert updated_organization.handle_name.value == "meow"
    end
  end

  describe "create_invite/2" do
    test "creates new invite." do
      organization = insert(:organization) |> Repo.preload([:invites])

      assert {:ok, %Organization{} = updated_organization} =
               Organization.create_invite(organization, %{
                 email_address: Faker.Internet.email(),
                 role: :member
               })
               |> Repo.update()

      updated_organization = Repo.preload(updated_organization, [:invites], force: true)

      assert length(updated_organization.invites) == 1
    end
  end

  describe "remove_invite/2" do
    # TODO test
  end

  describe "create_membership/2" do
    # TODO test
  end

  describe "remove_membership/2" do
    # TODO test
  end

  describe "change_role/3" do
    # TODO test
  end
end
