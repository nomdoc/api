defmodule API.Users do
  @moduledoc false

  use API, :context

  alias API.HandleName
  alias API.User

  @doc """
  Registers a user with password.
  """
  @spec register_user_with_password(binary(), binary()) :: {:ok, User.t()}
  def register_user_with_password(email_address, password) do
    with {:ok, user} <- maybe_create_user_with_password(email_address, password),
         :ok <- maybe_create_handle_name(user),
         do: {:ok, user}
  end

  defp maybe_create_user_with_password(email_address, password) do
    user_id = Ecto.UUID.generate()
    data = %{id: user_id, email_address: email_address, password: password}

    %User{}
    |> User.changeset(data)
    |> Repo.insert!(on_conflict: :nothing, conflict_target: :email_address)

    user = Repo.get_by!(User, email_address: email_address)

    {:ok, Map.put(user, :new?, user.id == user_id)}
  end

  defp maybe_create_handle_name(%User{} = user) do
    case user do
      %User{new?: true} = user ->
        user
        |> build_assoc(:handle_name)
        |> HandleName.changeset(%{value: HandleName.generate_value()})
        |> Repo.insert()
        |> case do
          {:ok, %HandleName{}} -> :ok
          reply -> reply
        end

      %User{} ->
        :ok
    end
  end

  @spec get_user_by_id(binary(), [term()]) :: {:ok, User.t()} | {:error, :user_not_found}
  def get_user_by_id(user_id, preloads \\ []) do
    Repo.get(User, user_id)
    |> Repo.preload(preloads)
    |> case do
      %User{} = user -> {:ok, user}
      nil -> {:error, :user_not_found}
    end
  end

  @spec update_display_name(binary(), binary()) ::
          {:ok, User.t()} | {:error, :user_not_found | Changeset.t()}
  def update_display_name(user_id, display_name) do
    case get_user_by_id(user_id) do
      {:ok, %User{} = user} ->
        user
        |> User.update_display_name(%{display_name: display_name})
        |> Repo.update()

      reply ->
        reply
    end
  end

  @spec update_handle_name(binary(), binary()) ::
          {:ok, User.t()} | {:error, :user_not_found | Changeset.t()}
  def update_handle_name(user_id, handle_name) do
    case get_user_by_id(user_id, [:handle_name]) do
      {:ok, %User{} = user} ->
        user
        |> User.update_handle_name(%{handle_name: handle_name})
        |> Repo.update()

      reply ->
        reply
    end
  end

  @spec update_bio(binary(), binary()) ::
          {:ok, User.t()} | {:error, :user_not_found | Changeset.t()}
  def update_bio(user_id, bio) do
    case get_user_by_id(user_id) do
      {:ok, %User{} = user} ->
        user
        |> User.update_bio(%{bio: bio})
        |> Repo.update()

      reply ->
        reply
    end
  end
end
