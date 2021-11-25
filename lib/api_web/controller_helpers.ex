defmodule APIWeb.ControllerHelpers do
  @moduledoc false

  @spec password_breached_message() :: binary()
  def password_breached_message() do
    "The password you provided has previously been breached. To increase your security, please change your password."
  end

  @spec password_invalid_message() :: binary()
  def password_invalid_message() do
    "Password must contain at least one lowercase alphabet, one uppercase alphabet, one number and one special charater."
  end
end
