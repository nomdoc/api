defmodule APIWeb.SchemaIdePlug do
  @moduledoc false

  @behaviour Plug

  @impl Plug
  defdelegate init(opts), to: Absinthe.Plug.GraphiQL

  @impl Plug
  defdelegate call(conn, opts), to: Absinthe.Plug.GraphiQL
end
