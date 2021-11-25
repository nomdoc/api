defmodule APIWeb.Router do
  use APIWeb, :router

  pipeline :rest do
    plug :accepts, ["json"]
    plug Accent.Plug.Request, transformer: Accent.Case.Snake

    plug Accent.Plug.Response,
      default_case: Accent.Case.Camel,
      supported_cases: %{"camel" => Accent.Case.Camel},
      json_codec: Phoenix.json_library()
  end

  pipeline :graph do
    plug :accepts, ["json"]
    plug APIWeb.SchemaContextPlug
  end

  scope "/oauth", APIWeb do
    pipe_through :rest

    post "/token", OAuthController, :token
    post "/revoke", OAuthController, :revoke
  end

  scope "/graph" do
    pipe_through :graph

    if Application.fetch_env!(:api, :compiled_env) == :dev do
      forward "/ide", APIWeb.SchemaIdePlug, schema: APIWeb.Schema
    end

    forward "/", APIWeb.SchemaPlug,
      schema: APIWeb.Schema,
      analyze_complexity: true

    # TODO add max complexity
    # max_complexity: 50
  end
end
