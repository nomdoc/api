defmodule API.RecaptchaProvider do
  @moduledoc false

  @callback check_assessment(binary(), binary()) :: :ok | {:error, :failed_recaptcha}
end
