defmodule APIWeb.ErrorView do
  @moduledoc false

  use APIWeb, :view

  require Logger

  def render("500.json", _assigns) do
    APIWeb.ErrorHandler.normalize(:internal_server_error)
  end

  def render("404.json", _assigns) do
    APIWeb.ErrorHandler.normalize(:not_found)
  end

  def render("400.json", %{reason: %Plug.Parsers.ParseError{exception: %Jason.DecodeError{}}}) do
    APIWeb.ErrorHandler.normalize(:invalid_json)
  end

  def render("400.json", _assigns) do
    APIWeb.ErrorHandler.normalize(:bad_request)
  end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.json" becomes
  # "Not Found".
  def template_not_found(template, _assigns) do
    Logger.error("#{template} is not handled in APIWeb.ErrorView")

    APIWeb.ErrorHandler.normalize(:unknown)
  end
end
