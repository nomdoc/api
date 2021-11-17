defmodule APIWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use APIWeb, :controller
      use APIWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  use Boundary, deps: [API], exports: [Endpoint]

  def controller() do
    quote do
      use Phoenix.Controller, namespace: APIWeb

      import Plug.Conn
      import APIWeb.Gettext
      import Ecto.Changeset
      import API.Utils

      alias APIWeb.Router.Helpers, as: Routes
    end
  end

  def resolver() do
    quote do
      use Absinthe.Schema.Notation

      import Ecto.Changeset
      import API.Utils
      import APIWeb.Utils

      alias API.Auth
      alias API.HandleName
      alias API.HandleNames
      alias API.Organization
      alias API.OrganizationInvite
      alias API.OrganizationMembership
      alias API.Organizations
      alias API.RefreshToken
      alias API.Repo
      alias API.User
      alias API.Users
      alias APIWeb.EnforceOrganizationAccessMiddleware
      alias APIWeb.EnforceProfileAccessMiddleware
      alias APIWeb.EnsureAuthenticatedMiddleware
      alias Ecto.Changeset
    end
  end

  def view() do
    quote do
      use Phoenix.View,
        root: "lib/api_web/templates",
        namespace: APIWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def router() do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel() do
    quote do
      use Phoenix.Channel
      import APIWeb.Gettext
    end
  end

  defp view_helpers() do
    quote do
      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import APIWeb.ErrorHelpers
      import APIWeb.Gettext
      alias APIWeb.Router.Helpers, as: Routes
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
