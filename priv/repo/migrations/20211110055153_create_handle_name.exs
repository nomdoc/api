defmodule API.Repo.Migrations.CreateHandleName do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table("handle_name", primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references("user", type: :binary_id, on_delete: :delete_all)
      add :organization_id, references("organization", type: :binary_id, on_delete: :delete_all)
      add :value, :string
      timestamps()
    end

    create unique_index("handle_name", [:user_id])
    create unique_index("handle_name", [:organization_id])
    create unique_index("handle_name", [:value])
  end
end
