defmodule APIApplication do
  @moduledoc false

  use Boundary, top_level?: true, deps: [API, APIWeb]
  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      API.Repo,
      # Start the Telemetry supervisor
      APIWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: API.PubSub},
      # Start the Endpoint (http/https)
      APIWeb.Endpoint,
      # Start a worker by calling: API.Worker.start_link(arg)
      # {API.Worker, arg}
      {Oban, Application.fetch_env!(:api, Oban)},
      GoogleCerts.CertificateCache
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: API.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    APIWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
