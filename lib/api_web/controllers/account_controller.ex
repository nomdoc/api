defmodule APIWeb.AccountController do
  @moduledoc false

  use APIWeb, :controller

  alias API.Auth
  alias API.Pwned
  alias API.RateLimiter
  alias API.Recaptcha
  alias API.Regex

  action_fallback APIWeb.FallbackController

  def register(%Plug.Conn{} = conn, data) do
    types = %{email_address: :string, password: :string, recaptcha_token: :string}
    params = Map.keys(types)

    {%{}, types}
    |> cast(data, params)
    |> validate_required(params, message: "Please fill in required fields.")
    |> parse_string(:email_address, scrub: :all, transform: :downcase)
    |> parse_string(:password, scrub: :all)
    |> parse_string(:recaptcha_token, scrub: :all)
    |> validate_length(:password, min: 12, message: password_invalid_message())
    |> validate_refutation(:password, &Pwned.password_breached?/1,
      message: password_breached_message()
    )
    |> validate_format(:password, Regex.password(), message: password_invalid_message())
    |> validate_email_address(:email_address)
    |> case do
      %Changeset{valid?: true} = changeset ->
        %{email_address: email_address, password: password, recaptcha_token: recaptcha_token} =
          apply_changes(changeset)

        ip_address = conn.remote_ip |> Tuple.to_list() |> Enum.join(".")

        with :ok <- Recaptcha.check_assessment(recaptcha_token, "register_account"),
             :ok <- RateLimiter.check_rate("register_account:#{ip_address}", 60 * 1_000, 4),
             {:ok, _user} <- Auth.register_with_password(email_address, password),
             do: render(conn, "register.json")

      changeset ->
        {:error, changeset}
    end
  end
end
