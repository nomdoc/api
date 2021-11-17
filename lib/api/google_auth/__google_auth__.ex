defmodule API.GoogleAuth do
  @moduledoc """
  A module that lets users sign in with Google. For more information, see
  https://developers.google.com/identity/gsi/web/guides/overview.

  ## Setup

  **For development / production**

  ```elixir
  # config.exs
  config :api, API.GoogleAuth, service: API.GoogleAuthHttp
  ```

  **For testing**

  ```elixir
  # config.exs
  config :api, API.GoogleAuth, service: API.GoogleAuthMock

  # test_helpers.exs
  Mox.defmock(API.GoogleAuthMock, for: API.GoogleAuthProvider)
  ```

  ## Configuration

  - `client_id`: Google OAuth 2.0 Client ID. It looks something like this
    `<OAUTH_CLIENT_ID>.apps.googleusercontent.com`.
  """

  @spec get_service() :: module()
  def get_service() do
    Application.fetch_env!(:api, API.GoogleAuth)[:service]
  end

  @spec get_config() :: %{client_id: binary()}
  def get_config() do
    %{client_id: Application.fetch_env!(:api, API.GoogleAuth)[:client_id]}
  end
end
