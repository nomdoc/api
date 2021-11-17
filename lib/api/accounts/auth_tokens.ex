defmodule API.AuthTokens do
  @moduledoc false

  use TypedStruct
  use Domo

  typedstruct do
    field :refresh_token, binary(), enforce: true
    field :access_token, binary(), enforce: true
    field :access_token_expired_at, binary(), enforce: true
  end
end
