defmodule APIWeb.SchemaContextPlug do
  @moduledoc false

  @behaviour Plug

  import Plug.Conn
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
    with ["Bearer " <> access_token] <- get_req_header(conn, "authorization"),
         {:ok, user} <- API.Auth.debug_access_token(access_token) do
      Logger.metadata(user_id: user.id)
      Logger.debug("Assigned current_user")
      Map.put(ctx, :current_user, user)
    else
      _reply -> ctx
    end
  end
end
