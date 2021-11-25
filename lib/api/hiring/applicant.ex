defmodule API.Applicant do
  @moduledoc false

  use API, :model

  schema "applicant" do
    field :entity_id, :string
    timestamps()
  end

  @spec changeset(t(), data) :: Changeset.t() when data: %{entity_id: binary()}
  def changeset(%__MODULE__{} = applicant, data) do
    params = ~w(entity_id)a

    applicant
    |> cast(data, params)
    |> validate_required(params)
    |> unique_constraint(:entity_id)
  end
end
