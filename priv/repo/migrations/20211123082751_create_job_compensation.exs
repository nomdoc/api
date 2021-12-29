defmodule API.Repo.Migrations.CreateJobCompensation do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table("job_compensation", primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :job_id, references("job", type: :binary_id, on_delete: :delete_all)
    end
  end
end
