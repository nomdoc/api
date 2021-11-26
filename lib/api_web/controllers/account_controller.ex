defmodule APIWeb.AccountController do
  @moduledoc false

  use APIWeb, :controller

  import API.Pwned

  alias API.Auth
  alias API.Regex

  action_fallback APIWeb.FallbackController

  def register(%Plug.Conn{} = conn, data) do
    types = %{email_address: :string, password: :string}
    params = Map.keys(types)

    {%{}, types}
    |> cast(data, params)
    |> validate_required(params, message: "Please fill in required fields.")
    |> parse_string(:email_address, scrub: :all, transform: :downcase)
    |> parse_string(:password, scrub: :all)
    |> validate_length(:password, min: 12, message: password_invalid_message())
    |> validate_refutation(:password, &password_breached?/1, message: password_breached_message())
    |> validate_format(:password, Regex.password(), message: password_invalid_message())
    |> validate_email_address(:email_address)
    |> case do
      %Changeset{valid?: true} = changeset ->
        %{email_address: email_address, password: password} = apply_changes(changeset)

        # TODO recaptcha
        # TODO rate limit
        with {:ok, _user} <- Auth.register_with_password(email_address, password),
             do: render(conn, "register.json")

      changeset ->
        {:error, changeset}
    end
  end
end
