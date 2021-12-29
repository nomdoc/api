defmodule API.Repo.Migrations.CreateRecruiter do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table("recruiter", primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :entity_id, :string
      timestamps()
    end

    create unique_index("recruiter", [:entity_id])
  end
end
