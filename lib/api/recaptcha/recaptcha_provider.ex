defmodule API.RecaptchaProvider do
  @moduledoc false

  # TODO return recaptcha assessment
  @callback create_assessment(binary(), binary()) :: {:ok, Finch.Response.t()} | {:error, term()}
end
