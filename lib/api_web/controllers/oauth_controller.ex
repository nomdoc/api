defmodule APIWeb.OAuthController do
  @moduledoc false

  use APIWeb, :controller

  action_fallback APIWeb.FallbackController

  def authorize(%Plug.Conn{} = conn, data) do
    case data["response_type"] do
      "login_token" -> login_with_token(conn, data)
      _reply -> {:error, :unsupported_response_type}
    end
  end

  def token(%Plug.Conn{} = conn, data) do
    case data["grant_type"] do
      "login_token" -> verify_login_token(conn, data)
      "google_id_token" -> verify_google_id_token(conn, data)
      "refresh_token" -> exchange_refresh_token(conn)
      _reply -> {:error, :unsupported_grant_type}
    end
  end

  def revoke(%Plug.Conn{} = conn, _data) do
    conn = fetch_cookies(conn)
    refresh_token_id = conn.cookies["refresh_token"]

    if is_binary(refresh_token_id) do
      :ok = API.Auth.logout(refresh_token_id)
    end

    conn
    |> delete_resp_cookie("refresh_token")
    |> render("revoke.json")
  end

  defp login_with_token(%Plug.Conn{} = conn, data) do
    types = %{email_address: :string}
    params = Map.keys(types)

    {%{}, types}
    |> cast(data, params)
    |> validate_required(params, message: "Please fill in required fields.")
    |> parse_string(:email_address, scrub: :all, transform: :downcase)
    |> validate_email_address(:email_address)
    |> case do
      %Ecto.Changeset{valid?: true} = changeset ->
        %{email_address: email_address} = apply_changes(changeset)

        # TODO recaptcha
        # TODO rate limit
        with {:ok, _user} <- API.Auth.login_with_token(email_address),
             do: render(conn, "authorize.json", data: %{email_address: email_address})

      changeset ->
        {:error, changeset}
    end
  end

  defp verify_login_token(%Plug.Conn{} = conn, data) do
    types = %{login_token: :string}
    params = Map.keys(types)

    {%{}, types}
    |> cast(data, params)
    |> validate_required(params, message: "Please fill in required fields.")
    |> parse_string(:login_token, scrub: :all)
    |> case do
      %Ecto.Changeset{valid?: true} = changeset ->
        %{login_token: login_token} = apply_changes(changeset)

        # TODO recaptcha
        # TODO rate limit
        with {:ok, tokens} <- API.Auth.verify_login_token(login_token),
             do:
               conn
               |> put_refresh_token_cookie(tokens.refresh_token)
               |> render("token.json", data: tokens)

      changeset ->
        {:error, changeset}
    end
  end

  defp verify_google_id_token(%Plug.Conn{} = conn, data) do
    types = %{google_id_token: :string}
    params = Map.keys(types)

    {%{}, types}
    |> cast(data, params)
    |> validate_required(params, message: "Please fill in required fields.")
    |> parse_string(:google_id_token, scrub: :all)
    |> case do
      %Ecto.Changeset{valid?: true} = changeset ->
        %{google_id_token: google_id_token} = apply_changes(changeset)

        # TODO recaptcha
        # TODO rate limit
        with {:ok, tokens} <- API.Auth.verify_google_id_token(google_id_token),
             do:
               conn
               |> put_refresh_token_cookie(tokens.refresh_token)
               |> render("token.json", data: tokens)

      changeset ->
        {:error, changeset}
    end
  end

  defp exchange_refresh_token(%Plug.Conn{} = conn) do
    conn = fetch_cookies(conn)
    refresh_token_id = conn.cookies["refresh_token"]

    # TODO recaptcha
    # TODO rate limit
    with :ok <- parse_uuid4(refresh_token_id),
         {:ok, tokens} <- API.Auth.exchange_refresh_token(refresh_token_id) do
      conn
      |> put_refresh_token_cookie(tokens.refresh_token)
      |> render("token.json", data: tokens)
    else
      _reply -> {:error, :unauthenticated}
    end
  end

  defp put_refresh_token_cookie(conn, refresh_token) do
    put_resp_cookie(conn, "refresh_token", refresh_token, refresh_token_cookie_opts())
  end

  # For more info, see https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html#domain-and-path-attributes
  defp refresh_token_cookie_opts() do
    [
      domain:
        if Application.fetch_env!(:api, :compiled_env) == :prod do
          "nomdoc.com"
        else
          "localhost"
        end,
      path: "/",
      # 30 days
      max_age: 30 * 24 * 60 * 60,
      http_only: true,
      secure: true,
      same_site: "Strict"
    ]
  end

  defp parse_uuid4(string) do
    if is_binary(string) do
      case UUID.info(string) do
        {:ok, info} ->
          version = Keyword.get(info, :version)

          if version == 4, do: :ok, else: {:error, :invalid_uuid4}

        _reply ->
          {:error, :invalid_uuid4}
      end
    else
      {:error, :must_be_string}
    end
  end
end
