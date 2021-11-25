defmodule APIWeb.SchemaContextPlug do
  @moduledoc false

  @behaviour Plug

  alias API.User

  require Logger

  @impl Plug
  def init(opts) do
    opts
  end

  @impl Plug
  def call(%Plug.Conn{} = conn, _opts) do
    context = build_current_user(%{}, conn)

    Absinthe.Plug.put_options(conn, context: context)
  end

  defp build_current_user(ctx, %Plug.Conn{} = conn) do
    case conn.assigns[:current_user] do
      nil ->
        ctx

      %User{} = user ->
        Logger.metadata(user_id: user.id)
        Logger.debug("Put Absinthe context 'current_user'")
        Map.put(ctx, :current_user, user)
    end
  end
end
