defmodule API.PwnedProvider do
  @moduledoc false

  @callback password_breached?(binary()) :: boolean()
end
