defmodule API.RecaptchaHttp do
  @moduledoc false

  @behaviour API.RecaptchaProvider

  alias API.Recaptcha

  require Logger

  @base_url "https://recaptchaenterprise.googleapis.com"

  @spec check_assessment(binary(), binary()) :: :ok | {:error, :failed_recaptcha}
  def check_assessment(token, expected_action) do
    case create_assessment(token, expected_action) do
      {:ok, %Req.Response{body: assessment}} ->
        # Only 0.1, 0.3, 0.7 and 0.9 score levels are available
        # https://cloud.google.com/recaptcha-enterprise/docs/interpret-assessment#interpret_scores
        score = assessment["score"]
        action = assessment["tokenProperties"]["action"]
        valid? = assessment["tokenProperties"]["valid"]

        if valid? and score >= 0.7 and action == expected_action,
          do: :ok,
          else: {:error, :failed_recaptcha}

      _reply ->
        {:error, :failed_recaptcha}
    end
  end

  # For more info, https://cloud.google.com/recaptcha-enterprise/docs/create-assessment
  defp create_assessment(token, expected_action) do
    config = Recaptcha.config()

    base_uri = Path.join([@base_url, "v1beta1", "projects", config.project_id, "assessments"])
    query = URI.encode_query(%{key: config.api_key})
    uri = "#{base_uri}?#{query}"

    data =
      Accent.Case.convert(
        %{event: %{token: token, site_key: config.site_key, expected_action: expected_action}},
        Accent.Case.Camel
      )

    build_and_run_request(:post, uri, body: {:json, data})
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
