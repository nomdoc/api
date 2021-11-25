defmodule API.GoogleUser do
  @moduledoc false

  use TypedStruct
  use Domo

  typedstruct do
    field :id, binary(), enforce: true
    field :email_address, binary(), enforce: true
    field :email_address_verified?, boolean(), enforce: true
    field :name, binary(), enforce: true
  end
end
