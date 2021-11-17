defmodule API.Mailer do
  @moduledoc """
  Document all the config
  """

  @spec get_service() :: module()
  def get_service() do
    Application.fetch_env!(:api, API.MailerProvider)[:service]
  end
end
