defmodule API.Country do
  @moduledoc false

  use TypedStruct
  use Domo

  typedstruct do
    field :name, binary(), enforce: true
    field :status, atom(), enforce: true
    field :code, binary(), enforce: true
    field :latitude, float(), enforce: true
    field :longitude, float(), enforce: true
    field :bounds, %{north: float(), south: float(), east: float(), west: float()}, enforce: true
  end
end
