defmodule API.RecaptchaHttp do
  @moduledoc false

  alias API.Recaptcha

  require Logger

  @base_url "https://recaptchaenterprise.googleapis.com"

  @doc """
  Create an assessment for reCAPTCHA response.

  For more info, https://cloud.google.com/recaptcha-enterprise/docs/create-assessment
  """
  @spec create_assessment(binary(), binary()) :: {:ok, Finch.Response.t()} | {:error, term()}
  def create_assessment(token, expected_action) do
    config = Recaptcha.get_config()

    base_uri = Path.join([@base_url, "v1beta1", "projects", config.project_id, "assessments"])
    query = URI.encode_query(%{key: config.api_key})
    uri = "#{base_uri}?#{query}"

    data =
      Accent.Case.convert(
        %{event: %{token: token, site_key: config.site_key, expected_action: expected_action}},
        Accent.Case.Camel
      )

    build_and_run_request(:post, uri, body: {:json, data})

    # TODO must check expectedAction vs tokenProperties.action
    # TODO must make sure score passes threshold
    # TODO handle other error
  end

  defp build_and_run_request(method, uri, options) do
    Req.build(method, uri, options)
    |> Req.put_default_steps(retry: true)
    |> debug_request()
    |> Req.run()
  end

  defp debug_request(%Req.Request{} = request) do
    Logger.debug("""
    Processing reCaptcha Enterprise request
      method: #{request.method}
      url: #{URI.to_string(request.url)}
      body: #{inspect(elem(request.body, 1))}
    """)

    request
  end
end
