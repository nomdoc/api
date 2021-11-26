defmodule API.MixProject do
  @moduledoc false

  use Mix.Project

  def project do
    [
      app: :api,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      test_paths: ["lib"],
      test_pattern: "*_test.exs",
      compilers: [:boundary, :phoenix, :gettext] ++ Mix.compilers() ++ [:domo_compiler],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {APIApplication, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:absinthe, "~> 1.6.6"},
      {:absinthe_phoenix, "~> 2.0.2"},
      {:absinthe_plug, "~> 1.5.8"},
      {:accent, "~> 1.1.1"},
      {:argon2_elixir, "~> 2.4.0"},
      {:bamboo, "~> 2.2.0"},
      {:bamboo_postmark, "~> 1.0.0"},
      {:burnex, "~> 3.1.0"},
      {:corsica, "~> 1.1.3"},
      {:dataloader, "~> 1.0.9"},
      {:domo, "~> 1.3.4"},
      {:ecto_enum, "~> 1.4.0"},
      {:ecto_sql, "~> 3.7.1"},
      {:elixir_uuid, "~> 1.2.1"},
      {:email_checker, "~> 0.2.1"},
      {:gettext, "~> 0.18.2"},
      {:hammer, "~> 6.0.0"},
      {:hammer_backend_redis, "~> 6.1.0"},
      {:jason, "~> 1.2.2"},
      {:joken, "~> 2.4.1"},
      {:nanoid, "~> 2.0.5"},
      {:oban, "~> 2.10.1"},
      {:paginator, "~> 1.0.4"},
      {:phoenix, "~> 1.6.2"},
      {:phoenix_ecto, "~> 4.4.0"},
      {:plug_cowboy, "~> 2.5.2"},
      {:postgrex, ">= 0.0.0"},
      {:remote_ip, "~> 1.0.0"},
      {:req, "~> 0.2.1"},
      {:telemetry, "~> 1.0.0", override: true},
      {:telemetry_metrics, "~> 0.6.1"},
      {:telemetry_poller, "~> 1.0.0"},
      {:typed_struct, "~> 0.2.1"},

      # Build libs
      {:dotenvy, "~> 0.5.0"},

      # Dev / Test libs
      {:boundary, "~> 0.8.0", runtime: false},
      {:credo, "~> 1.5.6", only: [:dev, :test], runtime: false},
      {:ex_machina, "~> 2.7.0", only: [:test]},
      {:faker, "~> 0.16.0", only: [:test]},
      {:mox, "~> 1.0.1", only: [:test]}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      reset: ["ecto.drop", "setup"],
      test: [
        "ecto.drop",
        "ecto.create --quiet",
        "ecto.migrate --quiet",
        "test"
      ]
    ]
  end
end
