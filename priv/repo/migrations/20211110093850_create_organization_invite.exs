defmodule API.Repo.Migrations.CreateOrganizationInvite do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table("organization_invite", primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :organization_id, references("organization", type: :binary_id, on_delete: :delete_all)
      add :user_id, references("user", type: :binary_id, on_delete: :delete_all)
      add :email_address, :string
      add :role, :integer
      timestamps()
    end

    create unique_index("organization_invite", [:user_id, :organization_id])
    create unique_index("organization_invite", [:email_address, :organization_id])
  end
end
