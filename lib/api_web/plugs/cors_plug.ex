defmodule APIWeb.CorsPlug do
  @moduledoc false

  use Corsica.Router,
    origins: {__MODULE__, :origin_allowed?},
    allow_headers: ["accept", "accept-language", "content-type", "authorization"],
    allow_credentials: true,
    log: [rejected: :error, invalid: :warn, accepted: :debug]

  resource("/*", allow_methods: ["POST"])

  @allowed_urls ["https://nomdoc.com"]

  @spec origin_allowed?(binary()) :: boolean()
  def origin_allowed?(url) do
    if Application.fetch_env!(:api, :compiled_env) in [:dev, :test] do
      true
    else
      url in @allowed_urls
    end
  end
end
