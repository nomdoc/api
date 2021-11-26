defmodule API.Utils do
  @moduledoc false

  import Ecto.Changeset

  alias Ecto.Changeset

  @doc """
  Generates an `n` digit code padded with leading zero(s). For example, "012345" and "123456".
  """
  @spec generate_digit_code(length: pos_integer()) :: binary()
  def generate_digit_code(opts \\ []) do
    length = Keyword.get(opts, :length) || 6

    :rand.seed(:default, :os.timestamp())

    String.duplicate("9", length)
    |> String.to_integer()
    |> :rand.uniform()
    |> Integer.to_string()
    |> String.pad_leading(length, "0")
  end

  @doc """
  Hashes a plaintext using SHA256 HMAC.
  """
  @spec hmac(binary(), binary()) :: binary()
  def hmac(secret_key, plain_text) do
    :crypto.mac(:hmac, :sha256, secret_key, plain_text) |> Base.encode64()
  end

  @doc """
  Checks if a hash belongs to the plain text.
  """
  @spec hmac_matched?(binary(), binary(), binary()) :: boolean()
  def hmac_matched?(secret_key, plain_text, original_hash) do
    compared_hash = hmac(secret_key, plain_text)
    compared_hash == original_hash
  end

  @doc """
  Returns the OS current time in seconds.
  """
  @spec current_timestamp() :: pos_integer
  def current_timestamp() do
    DateTime.utc_now() |> DateTime.to_unix()
  end

  @doc """
  Checks if a timestamp is valid.
  """
  @spec timestamp_valid?(binary()) :: boolean()
  def timestamp_valid?(timestamp) do
    current_timestamp() <= timestamp
  end

  @doc """
  Checks if given DateTime is expired.
  """
  @spec expired?(DateTime.t()) :: boolean()
  def expired?(expiration_dt) do
    current_dt = DateTime.utc_now()

    case DateTime.compare(expiration_dt, current_dt) do
      result when result in [:gt, :eq] -> false
      _reply -> true
    end
  end

  @doc """
  Converts a struct to map.
  """
  @spec convert_struct_to_map(struct() | module()) :: map()
  def convert_struct_to_map(%model{} = data) do
    Map.take(data, model.__schema__(:fields))
  end

  @doc """
  Indicates whether an email is valid.
  """
  @spec valid_email?(binary()) :: boolean
  def valid_email?(email_address) do
    EmailChecker.valid?(email_address) and not Burnex.is_burner?(email_address)
  end

  @doc """
  Asserts a field is a truthy value.

  ## Options

    * `message` - The message on failure.

  ## Examples

      validate_assertion(changeset, :password, &password_breached?/1)
  """
  @spec validate_assertion(Changeset.t(), atom(), (any() -> boolean()), opts) :: Changeset.t()
        when opts: [message: binary()]
  def validate_assertion(%Changeset{} = changeset, field, func, opts \\ []) do
    value = get_field(changeset, field)
    message = Keyword.get(opts, :message) || "Expected to be true."

    if func.(value) do
      changeset
    else
      add_error(changeset, field, message)
    end
  end

  @doc """
  Asserts a field is false.

  ## Options

    * `message` - The message on failure.

  ## Examples

      validate_refutation(changeset, :password, &password_breached?/1)
  """
  @spec validate_refutation(Changeset.t(), atom(), (any() -> boolean()), opts) :: Changeset.t()
        when opts: [message: binary()]
  def validate_refutation(%Changeset{} = changeset, field, func, opts \\ []) do
    value = get_field(changeset, field)
    message = Keyword.get(opts, :message) || "Expected to be true."

    if func.(value) do
      add_error(changeset, field, message)
    else
      changeset
    end
  end

  @doc """
  Validates that one of the fields are present in the changeset.

  ## Options

    * `message` - The message on failure.

  ## Examples

      validate_required_one_of(changeset, [:phone_number, :email_address])

  ## Credits

  Copied from https://stackoverflow.com/a/42212602/3372087.
  """
  @spec validate_required_one_of(Changeset.t(), [atom()], opts) :: Changeset.t()
        when opts: [message: binary()]
  def validate_required_one_of(%Changeset{} = changeset, fields, opts \\ []) do
    message =
      Keyword.get(opts, :message) || "One of these fields must be present: #{inspect(fields)}"

    if Enum.any?(fields, &present?(changeset, &1)) do
      changeset
    else
      add_error(changeset, hd(fields), message)
    end
  end

  @doc """
  Validates email address format and ensures email address exists and is not a
  temporary email.

  ## Options

    * `message` - The message on failure.

  ## Examples

      validate_email_address(changeset, :email_address)
  """
  @spec validate_email_address(Changeset.t(), atom(), opts) :: Changeset.t()
        when opts: [message: binary()]
  def validate_email_address(%Changeset{} = changeset, field, opts \\ []) do
    value = get_field(changeset, field)
    message = Keyword.get(opts, :message) || "Email address is invalid."

    cond do
      is_nil(value) -> changeset
      is_binary(value) and valid_email?(value) -> changeset
      true -> add_error(changeset, field, message)
    end
  end

  defp present?(%Changeset{} = changeset, field) do
    value = get_field(changeset, field)
    value && value != ""
  end

  @doc """
  Formats and validates a string.

  ## Options

    * `scrub?` - Indicates how whitespace should be removed. By default, string
      is always trimmed.
    * `transform` - Indicates what transformation needs to be done.
    * `message` - The message on failure.

  ## Examples

      parse_string(changeset, :name)
      parse_string(changeset, :name, scrub: :all)
      parse_string(changeset, :name, scrub: :upcase)
      parse_string(changeset, :name, message: "Not a good string.")
  """
  @spec parse_string(Changeset.t(), atom(), opts) :: Changeset.t()
        when opts: [
               scrub: :trim | :all,
               transform: :downcase | :upcase | :capitalize,
               message: binary()
             ]
  def parse_string(%Changeset{} = changeset, field, opts \\ []) do
    value = get_field(changeset, field)
    scrub_type = Keyword.get(opts, :scrub) || :trim
    transform_type = Keyword.get(opts, :transform)

    with {:ok, value} <- scrub_value(value, scrub_type),
         {:ok, value} <- transform_value(value, transform_type),
         do: put_change(changeset, field, value)
  end

  defp scrub_value(value, type) do
    cond do
      is_nil(value) -> {:ok, value}
      type == :trim -> {:ok, String.trim(value)}
      # TODO this won't work with no-space whitespace unicode
      type == :all -> {:ok, String.split(value) |> Enum.join()}
    end
  end

  defp transform_value(value, type) do
    cond do
      is_nil(value) -> {:ok, value}
      is_nil(type) -> {:ok, value}
      type == :downcase -> {:ok, String.downcase(value)}
      type == :upcase -> {:ok, String.upcase(value)}
      type == :capitalize -> {:ok, String.capitalize(value)}
    end
  end
end
