defmodule APIWeb.Dataloader do
  @moduledoc false

  @callback add_source(Dataloader.t()) :: Dataloader.t()
end
