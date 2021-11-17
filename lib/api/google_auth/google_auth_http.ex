defmodule API.GoogleAuthHttp do
  @moduledoc false

  @behaviour API.GoogleAuthProvider

  alias API.GoogleIdToken
  alias API.GoogleUser

  @spec verify_id_token(binary()) ::
          {:ok, API.GoogleUser.t()} | {:error, :invalid_google_id_token}
  def verify_id_token(token) do
    case GoogleIdToken.verify_and_validate(token) do
      {:ok, claims} ->
        {:ok,
         %GoogleUser{
           id: Map.get(claims, "sub"),
           email_address: Map.get(claims, "email"),
           email_address_verified: Map.get(claims, "email_verified"),
           name: Map.get(claims, "name")
         }}

      _reply ->
        {:error, :invalid_google_id_token}
    end
  end
end
