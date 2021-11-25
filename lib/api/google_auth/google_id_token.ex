defmodule API.GoogleIdToken do
  @moduledoc false

  use Joken.Config, default_signer: nil

  alias API.GoogleAuth

  @iss "https://accounts.google.com"

  # reference your custom verify hook here
  add_hook(API.GoogleIdToken.VerifyHook)

  @impl Joken.Config
  def token_config() do
    config = GoogleAuth.config()

    default_claims(skip: [:aud, :iss])
    |> add_claim("iss", nil, &(&1 == @iss))
    |> add_claim("aud", nil, &(&1 == config.client_id))
  end
end

defmodule API.GoogleIdToken.VerifyHook do
  @moduledoc false

  use Joken.Hooks

  @impl Joken.Hooks
  def before_verify(_options, {jwt, %Joken.Signer{} = _signer}) do
    with {:ok, %{"kid" => kid}} <- Joken.peek_header(jwt),
         {:ok, algorithm, key} <- GoogleCerts.fetch(kid) do
      {:cont, {jwt, Joken.Signer.create(algorithm, key)}}
    else
      _error -> {:halt, {:error, :no_signer}}
    end
  end
end
