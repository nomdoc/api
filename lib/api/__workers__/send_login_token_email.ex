defmodule API.Workers.SendLoginTokenEmail do
  @moduledoc false

  use Oban.Worker,
    queue: :mailer,
    max_attempts: 3,
    unique: [fields: [:args, :worker], keys: [:login_id]]

  require Logger

  @spec schedule(binary(), API.Login.t()) :: :ok
  def schedule(email_address, %API.Login{} = login) do
    params = %{
      email_address: email_address,
      login_id: login.id,
      login_token: login.token
    }

    params
    |> __MODULE__.new()
    |> Oban.insert!()

    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: params}) do
    Logger.debug("""
    Sending email...
      To: #{params["email_address"]}
      Message: Your login link: http://localhost:3000/login?token=#{params["login_token"]}
    """)

    :ok
  end
end
