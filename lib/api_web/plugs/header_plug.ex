defmodule APIWeb.HeaderPlug do
  @moduledoc false

  @behaviour Plug

  import Plug.Conn

  @impl Plug
  def init(opts) do
    opts
  end

  @impl Plug
  def call(%Plug.Conn{} = conn, _opts) do
    conn
    |> put_resp_header("x-content-type-options", "nosniff")
    |> put_resp_header("x-dns-prefetch-control", "on")
    |> put_resp_header("x-frame-options", "deny")
    |> delete_resp_header("x-powered-by")
  end
end
