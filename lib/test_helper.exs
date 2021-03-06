Mox.defmock(API.MailerMock, for: API.MailerProvider)
Mox.defmock(API.RecaptchaMock, for: API.RecaptchaProvider)
Mox.defmock(API.PwnedMock, for: API.PwnedProvider)
Mox.defmock(API.RateLimiterMock, for: API.RateLimiterProvider)

ExUnit.configure(exclude: :pending)
ExUnit.start()
Faker.start()
Ecto.Adapters.SQL.Sandbox.mode(API.Repo, :manual)
