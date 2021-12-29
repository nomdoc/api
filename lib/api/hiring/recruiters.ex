defmodule API.Recruiters do
  @moduledoc false

  use API, :context

  alias API.Recruiter

  @spec get_recruiter(binary(), [term()]) :: {:ok, Recruiter.t()}
  def get_recruiter(entity_id, preloads \\ []) do
    Repo.get_by(Recruiter, entity_id: entity_id)
    |> Repo.preload(preloads)
    |> case do
      %Recruiter{} = recruiter -> {:ok, recruiter}
      nil -> maybe_create_recruiter(entity_id)
    end
  end

  defp maybe_create_recruiter(entity_id, preloads \\ []) do
    recruiter_id = Ecto.UUID.generate()
    data = %{id: recruiter_id, entity_id: entity_id}

    %Recruiter{}
    |> Recruiter.changeset(data)
    |> Repo.insert!(on_conflict: :nothing)

    recruiter =
      Repo.get_by!(Recruiter, entity_id: entity_id)
      |> Repo.preload(preloads)

    {:ok, Map.put(recruiter, :new?, recruiter.id == recruiter_id)}
  end
end
