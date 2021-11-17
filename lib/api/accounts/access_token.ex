defmodule API.AccessToken do
  @moduledoc false

  @spec new(binary()) :: {:ok, binary()}
  def new(user_id) do
    extra_claims = %{"sub" => user_id}

    {:ok, Joken.generate_and_sign!(default_claims(), extra_claims, signer())}
  end

  @spec verify(binary()) :: {:ok, Joken.claims()} | {:error, :invalid_access_token}
  def verify(access_token) do
    case Joken.verify_and_validate(default_claims(), access_token, signer()) do
      {:ok, claims} -> {:ok, claims}
      _reply -> {:error, :invalid_access_token}
    end
  end

  @spec peek_claims(binary()) :: {:ok, Joken.claims()}
  def peek_claims(access_token) do
    {:ok, claims} = Joken.peek_claims(access_token)

    {:ok, claims}
  end

  defp default_claims() do
    %{}
    |> add_claim("jti", fn -> Joken.generate_jti() end)
    |> add_claim("exp", &generate_exp/0, &validate_exp/3)
    |> add_claim("iss", fn -> "https://api.nomdoc.com" end, &(&1 == "https://api.nomdoc.com"))
    |> add_claim("aud", fn -> "https://api.nomdoc.com" end, &(&1 == "https://api.nomdoc.com"))
  end

  defp add_claim(claims, key, generate_fun, validate_fun \\ nil, options \\ []) do
    Joken.Config.add_claim(claims, key, generate_fun, validate_fun, options)
  end

  defp generate_exp() do
    Joken.current_time() + time_to_live()
  end

  defp validate_exp(exp, _claims, _context) do
    Joken.current_time() < exp
  end

  defp time_to_live() do
    Application.fetch_env!(:api, API.Accounts)[:access_token_ttl]
  end

  defp signer() do
    Joken.Signer.create("HS256", signer_key())
  end

  defp signer_key() do
    Application.fetch_env!(:api, API.Accounts)[:access_token_signer_key]
  end
end
