defmodule API.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: API.Repo

  def user_factory() do
    %API.User{
      handle_name: build(:handle_name),
      email_address: Faker.Internet.email()
    }
  end

  def organization_factory() do
    %API.Organization{
      handle_name: build(:handle_name)
    }
  end

  def organization_invite_factory() do
    %API.OrganizationInvite{
      organization: build(:organization),
      email_address: Faker.Internet.email(),
      role: :member
    }
  end

  def user_organization_invite_factory() do
    %API.OrganizationInvite{
      organization: build(:organization),
      user: build(:user),
      role: :member
    }
  end

  def organization_membership_factory() do
    %API.OrganizationMembership{
      organization: build(:organization),
      user: build(:user),
      role: :member
    }
  end

  def handle_name_factory() do
    %API.HandleName{
      value: API.HandleName.generate_value()
    }
  end

  def login_factory() do
    token = API.Login.generate_token()

    %API.Login{
      user: build(:user),
      token: token,
      token_hash: API.Login.hash_token(token),
      expired_at: API.Login.generate_expired_at()
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
      email_address_verified: true,
      name: Faker.Person.name()
    }
  end
end
