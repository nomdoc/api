defmodule API.MailerPostmark do
  @moduledoc false

  @behaviour API.MailerProvider

  @spec send_email(binary()) :: :ok
  def send_email(_email) do
    :ok
  end
end
