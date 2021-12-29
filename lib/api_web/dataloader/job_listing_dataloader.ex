defmodule APIWeb.JobListingDataloader do
  @moduledoc false

  alias API.JobListing
  alias API.User

  @key :job_listing

  @spec add_source(Dataloader.t()) :: Dataloader.t()
  def add_source(loader) do
    Dataloader.add_source(loader, @key, Dataloader.KV.new(&query/2))
  end

  @spec load_listings(
          Dataloader.t(),
          API.User.t() | API.Organization.t(),
          API.Repo.paginate_opts()
        ) :: Dataloader.t()
  def load_listings(%Dataloader{} = loader, %User{} = user, opts \\ %{}) do
    Dataloader.load(loader, @key, {:listings, opts}, user)
  end

  @spec get_listings(
          Dataloader.t(),
          API.User.t() | API.Organization.t(),
          API.Repo.paginate_opts()
        ) :: API.Pagination.t()
  def get_listings(%Dataloader{} = loader, %User{} = user, opts \\ %{}) do
    Dataloader.get(loader, @key, {:listings, opts}, user)
  end

  defp query(batch_key, data) do
    case batch_key do
      {:listings, opts} -> fetch_listings(data, opts)
    end
  end

  defp fetch_listings(data, opts) do
    listings =
      data
      |> Enum.map(& &1.id)
      |> Enum.uniq()
      |> Enum.map(fn entity_id ->
        case JobListing.fetch_listings(entity_id, opts) do
          {:ok, %API.Pagination{} = pagination} ->
            API.Pagination.put_metadata(pagination, :entity_id, entity_id)

          _reply ->
            nil
        end
      end)

    Enum.reduce(data, %{}, fn %{id: entity_id} = item, result ->
      Map.put(result, item, Enum.find(listings, &(&1.metadata.entity_id == entity_id)))
    end)
  end
end
