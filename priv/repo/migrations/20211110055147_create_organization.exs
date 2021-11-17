defmodule API.Repo.Migrations.CreateOrganization do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table("organization", primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :display_name, :string
      add :bio, :string
      add :email_address, :string
      timestamps()
    end
  end
end
