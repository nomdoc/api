defmodule API.OrganizationMembershipTest do
  @moduledoc false

  use API.DataCase, async: true

  alias API.OrganizationMembership

  describe "changeset/2" do
    test "validates user ID and organization ID are unique." do
      membership = insert(:organization_membership)

      assert {:error, %Changeset{} = changeset} =
               OrganizationMembership.changeset(%OrganizationMembership{}, %{
                 user_id: membership.user.id,
                 organization_id: membership.organization.id,
                 role: :member
               })
               |> Repo.insert()

      assert errors_on(changeset)[:user_id] == ["has already been taken"]
    end
  end
end
