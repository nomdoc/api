defmodule API.Pwned do
  @moduledoc false

  @behaviour API.PwnedProvider

  @spec password_breached?(binary()) :: boolean()
  def password_breached?(password) do
    impl().password_breached?(password)
  end

  defp impl() do
    Application.fetch_env!(:api, API.Pwned)[:impl]
  end
end
