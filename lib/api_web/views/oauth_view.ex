defmodule APIWeb.OAuthView do
  @moduledoc false

  use APIWeb, :view

  def render("token.json", %{data: data}) do
    %{
      refresh_token: data.refresh_token,
      access_token: data.access_token,
      access_token_expired_at: data.access_token_expired_at
    }
  end

  def render("revoke.json", _assigns) do
    %{message: "Goodbye! See you again!"}
  end
end
