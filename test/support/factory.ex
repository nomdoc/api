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

  def recruiter_factory() do
    %API.Recruiter{
      entity_id: Ecto.UUID.generate()
    }
  end

  def job_factory() do
    %API.Job{
      recruiter: build(:recruiter),
      employment_type: :locum,
      title: Faker.Lorem.sentence(3..5)
    }
  end
end
