defmodule APIWeb.UserType do
  @moduledoc false

  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 3]
  import APIWeb.SchemaHelpers

  alias API.User

  object :user do
    @desc "The user's ID."
    field :id, non_null(:id)

    @desc "The user's name."
    field :display_name, :string

    @desc "The user's bio."
    field :bio, :string

    @desc "The user's handle name."
    field :handle_name, non_null(:string),
      resolve:
        dataloader(:repo, :handle_name,
          callback: fn %API.HandleName{} = handle_name, _parent, _args ->
            {:ok, handle_name.value}
          end
        )

    @desc "The user's email address."
    field :email_address, :string, resolve: &email_address/3

    @desc "Identifies the date and time when user joined."
    field :joined_at, non_null(:datetime), resolve: &joined_at/3

    @desc "Indicates whether the user is the viewing user."
    field :is_viewer, non_null(:boolean), resolve: &is_viewer/3

    @desc "Indicates whether the user is an admin at Nomdoc."
    field :is_admin, non_null(:boolean), resolve: &is_admin/3
  end

  defp email_address(%User{} = user, _args, resolution) do
    case get_current_user(resolution) do
      {:ok, %User{} = current_user} ->
        # vNext: allow user to set visibility
        if user.id == current_user.id || current_user.role == :superuser do
          {:ok, user.email_address}
        else
          {:ok, nil}
        end

      _reply ->
        {:ok, nil}
    end
  end

  defp joined_at(%User{inserted_at: inserted_at}, _args, _resolution) do
    {:ok, inserted_at}
  end

  defp is_viewer(%User{id: user_id}, _args, resolution) do
    case get_current_user(resolution) do
      {:ok, %User{id: ^user_id}} -> {:ok, true}
      _reply -> {:ok, false}
    end
  end

  defp is_admin(%User{} = user, _args, _resolution) do
    {:ok, user.role in [:superuser, :admin]}
  end
end
