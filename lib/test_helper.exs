Mox.defmock(API.MailerMock, for: API.MailerProvider)
Mox.defmock(API.GoogleAuthMock, for: API.GoogleAuthProvider)
Mox.defmock(API.RecaptchaMock, for: API.RecaptchaProvider)

ExUnit.configure(exclude: :pending)
ExUnit.start()
Faker.start()
Ecto.Adapters.SQL.Sandbox.mode(API.Repo, :manual)
