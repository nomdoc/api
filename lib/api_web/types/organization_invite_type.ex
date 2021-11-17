defmodule APIWeb.OrganizationInviteType do
  @moduledoc false

  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  object :organization_invite do
    @desc "ID of the organization invite."
    field :id, non_null(:uuid4)

    field :role, non_null(:organization_membership_role)

    field :organization, non_null(:organization), resolve: dataloader(:repo)

    field :user, non_null(:user), resolve: dataloader(:repo)
  end
end
