defmodule API.Repo.Migrations.CreateJob do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table("job", primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :recruiter_id, references("recruiter", type: :binary_id, on_delete: :delete_all)
      add :status, :integer
      add :employment_type, :integer
      add :parent_job_id, references("job", type: :binary_id, on_delete: :delete_all)
      add :title, :string
      add :description, :string
      add :time_zone, :string
      add :starts_at, :utc_datetime_usec
      add :ends_at, :utc_datetime_usec
      add :address_latitude, :float
      add :address_longitude, :float
      add :address_line_one, :string
      add :address_line_two, :string
      add :address_city, :string
      add :address_state, :string
      add :address_postal_code, :string
      add :address_country_code, :string
      timestamps()
    end
  end
end
