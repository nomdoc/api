defmodule API.GoogleAuthProvider do
  @moduledoc false

  @callback verify_id_token(binary()) ::
              {:ok, API.GoogleUser.t()} | {:error, :invalid_google_id_token}
end
