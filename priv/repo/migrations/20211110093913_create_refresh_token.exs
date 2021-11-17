defmodule API.Repo.Migrations.CreateRefreshToken do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table("refresh_token", primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references("user", type: :binary_id, on_delete: :delete_all)
      add :status, :integer
      add :absolute_timeout_at, :utc_datetime_usec
      timestamps()
    end
  end
end
