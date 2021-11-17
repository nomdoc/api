defmodule API.Recaptcha do
  @moduledoc """
  Integrate the reCAPTCHA Enterprise API into user interactions on your site or
  app to score these user interactions for risk and potential fraud.

  ## Setup

  **For development / production**

  ```elixir
  # config.exs
  config :api, API.Recaptcha, service: API.RecaptchaHttp
  ```

  **For testing**

  ```elixir
  # config.exs
  config :api, API.Recaptcha, service: API.RecaptchaMock

  # test_helpers.exs
  Mox.defmock(API.RecaptchaMock, for: API.RecaptchaProvider)
  ```

  ## Configuration

  - `project_id`: Google Cloud project ID.
  - `api_key`: Google Cloud API key.
  - `site_key`: Google reCAPTCHA Enterprise key.
  """

  @spec get_service() :: module()
  def get_service() do
    Application.fetch_env!(:api, API.Recaptcha)[:service]
  end

  @spec get_config() :: %{api_key: binary(), project_id: binary(), site_key: binary()}
  def get_config() do
    %{
      project_id: Application.fetch_env!(:api, API.Recaptcha)[:project_id],
      api_key: Application.fetch_env!(:api, API.Recaptcha)[:api_key],
      site_key: Application.fetch_env!(:api, API.Recaptcha)[:site_key]
    }
  end
end
