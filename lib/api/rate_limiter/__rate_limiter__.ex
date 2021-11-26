defmodule API.RateLimiter do
  @moduledoc false

  @behaviour API.RateLimiterProvider

  @spec check_rate(binary(), integer(), integer()) :: :ok | {:error, :exceeded_rate_limit}
  def check_rate(id, scale_ms, limit) do
    impl().check_rate(id, scale_ms, limit)
  end

  defp impl() do
    Application.fetch_env!(:api, API.RateLimiter)[:impl]
  end
end
