defmodule APIWeb.Utils do
  @moduledoc false

  @spec get_current_user!(Absinthe.Resolution.t()) :: API.User.t()
  def get_current_user!(%Absinthe.Resolution{} = resolution) do
    case resolution |> Map.from_struct() |> get_in([:context, :current_user]) do
      %API.User{} = user ->
        user

      other_struct when is_struct(other_struct) ->
        raise BadStructError, struct: API.User, term: other_struct

      nil ->
        raise KeyError, key: :current_user, term: resolution
    end
  end

  @spec get_current_user(Absinthe.Resolution.t()) ::
          {:ok, API.User.t()} | {:error, :unauthenticated}
  def get_current_user(%Absinthe.Resolution{} = resolution) do
    case resolution |> Map.from_struct() |> get_in([:context, :current_user]) do
      %API.User{} = user ->
        {:ok, user}

      _reply ->
        {:error, :unauthenticated}
    end
  end

  @spec get_loader!(Absinthe.Resolution.t()) :: Dataloader.t()
  def get_loader!(%Absinthe.Resolution{} = resolution) do
    case resolution |> Map.from_struct() |> get_in([:context, :loader]) do
      %Dataloader{} = dataloader ->
        dataloader

      other_struct when is_struct(other_struct) ->
        raise BadStructError, struct: Dataloader, term: other_struct

      nil ->
        raise KeyError, key: :loader, term: resolution
    end
  end
end
