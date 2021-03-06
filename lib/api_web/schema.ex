defmodule APIWeb.Schema do
  @moduledoc false

  use Absinthe.Schema

  import_types(Absinthe.Type.Custom)
  import_types(APIWeb.ConnectionType)
  import_types(APIWeb.UserType)
  import_types(APIWeb.Uuid4Type)

  import_types(APIWeb.ProfileResolver)
  import_types(APIWeb.UserResolver)

  query do
    import_fields(:user_queries)
    import_fields(:profile_queries)
  end

  mutation do
    import_fields(:profile_mutations)
  end

  @impl Absinthe.Schema
  def context(ctx) do
    repo_source = Dataloader.Ecto.new(API.Repo)

    loader =
      Dataloader.new()
      |> Dataloader.add_source(:repo, repo_source)

    Map.put(ctx, :loader, loader)
  end

  @impl Absinthe.Schema
  def plugins() do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end

  @impl Absinthe.Schema
  def middleware(middleware, _field, _object) do
    # credo:disable-for-next-line Credo.Check.Refactor.AppendSingleItem
    middleware ++ [APIWeb.NormalizeErrorMiddleware]
  end
end
