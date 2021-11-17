defmodule API.Repo.Migrations.CreateOrganizationMembership do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table("organization_membership", primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :organization_id, references("organization", type: :binary_id, on_delete: :delete_all)
      add :user_id, references("user", type: :binary_id, on_delete: :delete_all)
      add :role, :integer
      add :visibility, :integer
      timestamps()
    end

    create unique_index("organization_membership", [:user_id, :organization_id])
  end
end
