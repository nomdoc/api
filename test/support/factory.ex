defmodule API.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: API.Repo

  def user_factory() do
    password = Faker.String.base64()

    %API.User{
      email_address: Faker.Internet.email(),
      password: password,
      password_hash: API.User.hash_password(password) |> Map.get(:password_hash),
      handle_name: build(:handle_name)
    }
  end

  def user_with_google_account_factory() do
    %API.User{
      email_address: Faker.Internet.email(),
      email_address_verified?: true,
      google_account_id: Faker.String.base64(),
      handle_name: build(:handle_name)
    }
  end

  def handle_name_factory() do
    %API.HandleName{
      value: API.HandleName.generate_value()
    }
  end

  def refresh_token_factory() do
    %API.RefreshToken{
      user: build(:user),
      absolute_timeout_at: API.RefreshToken.generate_absolute_timeout_at()
    }
  end

  def google_user_factory() do
    %API.GoogleUser{
      id: Faker.UUID.v4(),
      email_address: Faker.Internet.email(),
      email_address_verified?: true,
      name: Faker.Person.name()
    }
  end
end
