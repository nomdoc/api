defmodule APIWeb.SchemaPlug do
  @moduledoc false

  @behaviour Plug

  @impl Plug
  defdelegate init(opts), to: Absinthe.Plug

  @impl Plug
  def call(conn, opts) do
    Absinthe.Plug.call(conn, opts)
  end
end
