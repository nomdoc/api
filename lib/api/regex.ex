defmodule API.Regex do
  @moduledoc false

  @doc """
  Regex for handle name.

  ## Rules

  The handle name must:

    - Begin with an alphabet.
    - Have at least 4 or more characters.
    - Not exceed 39 characters.
    - Contain alphabets, numbers and hyphen only.
  """
  @spec handle_name() :: Regex.t()
  def handle_name(), do: ~r/^[a-z](?:[a-z\d]|-(?=[a-z\d])){3,38}$/

  @doc """
  Regex for email address. We only validates email address format.

  ## Credits

  http://emailregex.com/.
  """
  @spec email_address() :: Regex.t()
  def email_address(), do: ~r/^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$/

  @doc """
  Regex for password.

  ## Rules

  The password must have:

    - At least one upper case alphabet.
    - At least one lower case alphabet.
    - At least one digit.
    - At least one special character.

  ## Credits

  https://stackoverflow.com/a/19605207/3372087
  """
  @spec password() :: Regex.t()
  def password(), do: ~r/^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).*$/
end
