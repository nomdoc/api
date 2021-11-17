defmodule API.Repo.Migrations.CreateLogin do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table("login", primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references("user", type: :binary_id, on_delete: :delete_all)
      add :status, :integer
      add :token_hash, :string
      add :completed_at, :utc_datetime_usec
      add :expired_at, :utc_datetime_usec
      timestamps()
    end

    create unique_index("login", [:token_hash])
  end
end
