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

  @behaviour API.RecaptchaProvider

  @spec check_assessment(binary(), binary()) :: :ok | {:error, :failed_recaptcha}
  def check_assessment(token, expected_action) do
    impl().check_assessment(token, expected_action)
  end

  @spec config() :: %{api_key: binary(), project_id: binary(), site_key: binary()}
  def config() do
    %{
      project_id: Application.fetch_env!(:api, API.Recaptcha)[:project_id],
      api_key: Application.fetch_env!(:api, API.Recaptcha)[:api_key],
      site_key: Application.fetch_env!(:api, API.Recaptcha)[:site_key]
    }
  end

  defp impl() do
    Application.fetch_env!(:api, API.Recaptcha)[:impl]
  end
end
