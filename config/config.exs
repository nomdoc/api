# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :api,
  namespace: API,
  ecto_repos: [API.Repo],
  generators: [binary_id: true]

config :api, :compiled_env, Mix.env()

# Configures the endpoint
config :api, APIWeb.Endpoint,
  code_reloader: config_env() == :dev,
  debug_errors: false,
  check_origin: config_env() == :prod,
  render_errors: [view: APIWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: API.PubSub,
  watchers: []

if config_env() == :prod do
  # If you are doing OTP releases, you need to instruct Phoenix
  # to start each relevant endpoint.
  config :api, APIWeb.Endpoint, server: true
end

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

if config_env() == :prod do
  # Do not print debug messages in production
  config :logger, level: :info
end

if config_env() == :test do
  # Print only warnings and errors during test
  config :logger, level: :warn
end

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

if config_env() == :dev do
  # Set a higher stacktrace during development. Avoid configuring such
  # in production as building large stacktraces may be expensive.
  config :phoenix, :stacktrace_depth, 20

  # Initialize plugs at runtime for faster development compilation
  config :phoenix, :plug_init_mode, :runtime
end

# Configures Oban
config :api, Oban,
  repo: API.Repo,
  queues: [
    default: 10,
    mailer: 20
  ]

if config_env() == :test do
  config :api, Oban, queues: false, plugins: false
end

# See https://hexdocs.pm/argon2_elixir/Argon2.Stats.html for more
# configurations.
# The numbers are chosen following the guide provided in the doc.
#
#   ~60ms -> t_cost: 2, m_cost: 15
#   ~115ms -> t_cost: 4, m_cost: 15
#   ~208ms -> t_cost: 8, m_cost: 15
#   ~307ms -> t_cost: 12, m_cost: 15
#   ~415ms -> t_cost: 16, m_cost: 15
#   ~460ms -> t_cost: 18, m_cost: 15
#   ~525ms -> t_cost: 20, m_cost: 15
#
# 500ms is what's recommended as the most secure option. For more info, see
# https://elixirforum.com/t/staging-environment-how-to-debug-out-of-memory-errors-in-production-on-fly-io/42763/7
config :argon2_elixir,
  t_cost: 18,
  m_cost: 15

if config_env() == :test do
  config :argon2_elixir,
    t_cost: 1,
    m_cost: 8
end

config :api, API.Accounts,
  # Indicates the timeframe (in seconds) in which the access token will remain valid.
  access_token_ttl: 30 * 60,
  # Indicates the timeframe (in seconds) after which a refresh token will be invalidated.
  refresh_token_absolute_timeout: 100 * 24 * 60 * 60

if config_env() == :dev do
  config :api, API.Accounts, access_token_ttl: 24 * 60 * 60
end

config :api, API.Mailer, service: API.MailerPostmark
config :api, API.GoogleAuth, service: API.GoogleAuthHttp
config :api, API.Recaptcha, service: API.RecaptchaHttp
config :api, API.Pwned, impl: API.PwnedHttp

# For testing, we use service mocks as defined in test_helper.exs
if config_env() == :test do
  config :api, API.Mailer, service: API.MailerMock
  config :api, API.GoogleAuth, service: API.GoogleAuthMock
  config :api, API.Recaptcha, service: API.RecaptchaMock
end
