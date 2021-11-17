defmodule API.MailerProvider do
  @moduledoc false

  @callback send_email(binary()) :: :ok
end
