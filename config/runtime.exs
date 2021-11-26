import Config
import Dotenvy

if config_env() in [:dev, :test] do
  # This will load .env then .env.dev or .env.test.
  source!([".env", ".env.\#{config_env()}"])
end

database_url = env!("DATABASE_URL", :string!)
database_pool_size = env!("DATABASE_POOL_SIZE", :integer!)
redis_url = env!("REDIS_URL", :string!)
port = env!("PORT", :integer!)
host = env!("HOST", :string!)
host_port = env!("HOST_PORT", :integer!)
url_scheme = if host_port == 443, do: "https", else: "http"
secret_key_base = env!("SECRET_KEY_BASE", :string!)

login_token_hash_key = env!("LOGIN_TOKEN_HASH_KEY", :string!)
access_token_signer_key = env!("ACCESS_TOKEN_SIGNER_KEY", :string!)

google_project_id = env!("GOOGLE_PROJECT_ID", :string!)
google_recaptcha_api_key = env!("GOOGLE_RECAPTCHA_API_KEY", :string!)
google_recaptcha_site_key = env!("GOOGLE_RECAPTCHA_SITE_KEY", :string!)

config :api, APIWeb.Endpoint,
  url: [
    host: host,
    port: host_port,
    scheme: url_scheme
  ],
  http: [
    port: port,
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base

# TODO what is this for?
config :api, :host, host

if config_env() in [:dev, :prod] do
  config :api, API.Repo,
    # TODO: should we should SSL here or at load balancer?
    # ssl: true,
    url: database_url,
    pool_size: database_pool_size
else
  config :api, API.Repo,
    username: "postgres",
    password: "postgres",
    database: "nomdoc_test#{System.get_env("MIX_TEST_PARTITION")}",
    hostname: "localhost",
    pool: Ecto.Adapters.SQL.Sandbox
end

config :hammer,
  backend:
    {Hammer.Backend.Redis,
     [
       expiry_ms: 5 * 60 * 1_000,
       redis_url: [url: redis_url]
     ]}

config :api, API.Accounts,
  login_token_hash_key: login_token_hash_key,
  access_token_signer_key: access_token_signer_key

config :api, API.Recaptcha,
  project_id: google_project_id,
  api_key: google_recaptcha_api_key,
  site_key: google_recaptcha_site_key
