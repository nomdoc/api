defmodule API.Recruiter do
  @moduledoc false

  use API, :model

  alias API.Job

  schema "recruiter" do
    field :entity_id, :string
    field :new?, :boolean, virtual: true, default: false

    has_many :jobs, Job

    timestamps()
  end

  @spec changeset(t(), data) :: Changeset.t() when data: %{id: binary(), entity_id: binary()}
  def changeset(%__MODULE__{} = recruiter, data) do
    params = ~w(id entity_id)a

    recruiter
    |> cast(data, params)
    |> validate_required(params)
    |> unique_constraint(:entity_id)
  end
end
