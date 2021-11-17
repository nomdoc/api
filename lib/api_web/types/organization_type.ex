defmodule APIWeb.OrganizationType do
  @moduledoc false

  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 3, on_load: 2]
  import APIWeb.Utils

  alias API.Organization
  alias API.Organizations
  alias API.User

  object :organization do
    @desc "The organization's ID."
    field :id, non_null(:uuid4)

    @desc "The organization's name."
    field :display_name, :string

    @desc "The organization's bio."
    field :bio, :string

    @desc "The organization's handle name."
    field :handle_name, non_null(:string),
      resolve:
        dataloader(:repo, :handle_name,
          callback: fn %API.HandleName{} = handle_name, _parent, _args ->
            {:ok, handle_name.value}
          end
        )

    @desc "The organization's email address."
    field :email_address, :string, resolve: &email_address/3

    @desc "Identifies the date and time when organization was registered."
    field :registered_at, non_null(:datetime), resolve: &registered_at/3

    @desc "Viewer's invite in the organization."
    field :viewer_invite, :organization_invite, resolve: &viewer_invite/3

    @desc "Viewer's membership in the organization."
    field :viewer_membership, :organization_membership, resolve: &viewer_membership/3

    # TODO pagination?
    # field :members, list_of(:users)

    @desc "A list of all organization memberships."
    field :memberships, list_of(:organization_membership), resolve: &memberships/3
  end

  defp email_address(%Organization{} = organization, _args, resolution) do
    case get_current_user(resolution) do
      {:ok, %User{} = current_user} ->
        resolution
        |> get_loader!()
        |> load_memberships(organization)
        |> on_load(fn loader ->
          memberships = get_memberships(loader, organization)
          organization = put_memberships(organization, memberships)

          if Organizations.access?(organization, current_user) do
            {:ok, organization.email_address}
          else
            {:ok, nil}
          end
        end)

      _reply ->
        {:ok, nil}
    end
  end

  defp registered_at(%Organization{inserted_at: inserted_at}, _args, _resolution) do
    {:ok, inserted_at}
  end

  defp viewer_invite(%Organization{} = organization, _args, resolution) do
    case get_current_user(resolution) do
      {:ok, %User{} = current_user} ->
        resolution
        |> get_loader!()
        |> load_invites(organization)
        |> on_load(fn loader ->
          invites = get_invites(loader, organization)

          {:ok, Enum.find(invites, &(&1.user_id == current_user.id))}
        end)

      _reply ->
        {:ok, nil}
    end
  end

  defp viewer_membership(%Organization{} = organization, _args, resolution) do
    case get_current_user(resolution) do
      {:ok, %User{} = current_user} ->
        resolution
        |> get_loader!()
        |> load_memberships(organization)
        |> on_load(fn loader ->
          memberships = get_memberships(loader, organization)

          {:ok, Enum.find(memberships, &(&1.user_id == current_user.id))}
        end)

      _reply ->
        {:ok, nil}
    end
  end

  defp memberships(%Organization{} = organization, _args, resolution) do
    case get_current_user(resolution) do
      {:ok, %API.User{} = user} ->
        resolution
        |> get_loader!()
        |> load_memberships(organization)
        |> on_load(fn loader ->
          memberships = get_memberships(loader, organization)
          organization = put_memberships(organization, memberships)

          if Organizations.access?(organization, user) do
            {:ok, organization.memberships}
          else
            {:ok, nil}
          end
        end)

      _reply ->
        {:ok, nil}
    end
  end

  @invites_batch_key :invites

  defp load_invites(%Dataloader{} = loader, %Organization{} = organization) do
    Dataloader.load(loader, :repo, @invites_batch_key, organization)
  end

  defp get_invites(%Dataloader{} = loader, %Organization{} = organization) do
    Dataloader.get(loader, :repo, @invites_batch_key, organization)
  end

  @memberships_batch_key :memberships

  defp load_memberships(%Dataloader{} = loader, %Organization{} = organization) do
    Dataloader.load(loader, :repo, @memberships_batch_key, organization)
  end

  defp get_memberships(%Dataloader{} = loader, %Organization{} = organization) do
    Dataloader.get(loader, :repo, @memberships_batch_key, organization)
  end

  defp put_memberships(%Organization{} = organization, memberships) do
    Map.put(organization, @memberships_batch_key, memberships)
  end
end
