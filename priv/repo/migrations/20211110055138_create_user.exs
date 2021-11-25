defmodule API.Repo.Migrations.CreateUser do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table("user", primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :role, :integer
      add :email_address, :string
      add :email_address_verified?, :boolean
      add :password_hash, :string
      add :google_account_id, :string
      add :display_name, :string
      add :bio, :string
      add :gender, :integer
      timestamps()
    end

    create unique_index("user", [:email_address])
    create unique_index("user", [:google_account_id])
  end
end
