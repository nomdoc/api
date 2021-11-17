defmodule APIWeb.OrganizationMembershipType do
  @moduledoc false

  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias API.OrganizationMembership

  object :organization_membership do
    @desc "ID of the organization membership."
    field :id, non_null(:uuid4)

    field :role, non_null(:organization_membership_role)

    field :visibility, non_null(:organization_membership_visibility)

    field :organization, non_null(:organization), resolve: dataloader(:repo)

    field :user, non_null(:user), resolve: dataloader(:repo)

    field :joined_at, non_null(:datetime), resolve: &joined_at/3
  end

  enum :organization_membership_role do
    value(:owner)
    value(:member)
  end

  enum :organization_membership_visibility do
    value(:public, description: "The membership is visible to everyone.")
    value(:private, description: "The membership is visible only to those with explicit access.")
  end

  defp joined_at(%OrganizationMembership{inserted_at: inserted_at}, _args, _resolution) do
    {:ok, inserted_at}
  end
end
