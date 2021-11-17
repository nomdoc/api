defmodule API.Regex do
  @moduledoc false

  @doc """
  Regex for handle name.
  """
  @spec handle_name() :: Regex.t()
  def handle_name(), do: ~r/^[a-z](?:[a-z\d]|-(?=[a-z\d])){3,38}$/

  @doc """
  Regex for email address. We only validates email address format.
  Copied from http://emailregex.com/.
  """
  @spec email_address() :: Regex.t()
  def email_address(), do: ~r/^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$/
end
