defmodule APIWeb.CurrentUserPlug do
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
    with ["Bearer " <> access_token] <- get_req_header(conn, "authorization"),
         {:ok, user} <- API.Auth.debug_access_token(access_token) do
      Logger.metadata(user_id: user.id)
      Logger.debug("Assigned current_user")
      assign(conn, :current_user, user)
    else
      _reply -> conn
    end
  end
end
