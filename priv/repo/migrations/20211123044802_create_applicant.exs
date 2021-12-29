defmodule API.Repo.Migrations.CreateApplicant do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table("applicant", primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :entity_id, :string
      timestamps()
    end

    create unique_index("applicant", [:entity_id])
  end
end
