defmodule API.HandleNames do
  @moduledoc false

  use API, :context

  alias API.HandleName
  alias API.Organization
  alias API.Organizations
  alias API.User

  @spec validate_handle_name(binary()) :: :ok | {:error, :handle_name_has_been_taken}
  def validate_handle_name(handle_name) do
    query = from hn in HandleName, where: hn.value == ^handle_name

    if API.Repo.exists?(query) do
      {:error, :handle_name_has_been_taken}
    else
      :ok
    end
  end

  @spec get_account(binary()) :: {:ok, User.t() | Organization.t()} | {:error, :account_not_found}
  def get_account(handle_name) do
    case Repo.get_by(HandleName, value: handle_name) do
      %HandleName{user_id: user_id} = handle_name when is_binary(user_id) ->
        {:ok, handle_name |> Repo.preload([:user]) |> Map.get(:user)}

      %HandleName{organization_id: org_id} = handle_name when is_binary(org_id) ->
        {:ok, handle_name |> Repo.preload([:organization]) |> Map.get(:organization)}

      nil ->
        {:error, :account_not_found}
    end
  end

  @spec access?(binary, User.t()) :: boolean()
  def access?(handle_name, %User{id: user_id} = user) do
    case get_account(handle_name) do
      {:ok, %User{id: ^user_id}} -> true
      {:ok, %User{}} -> user.role == :superuser
      {:ok, %Organization{} = organization} -> Organizations.access?(organization, user)
      _reply -> false
    end
  end
end
