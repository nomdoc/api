defmodule API.RateLimiterHammer do
  @moduledoc false

  @behaviour API.RateLimiterProvider

  @spec check_rate(binary(), integer(), integer()) :: :ok | {:error, :exceeded_rate_limit}
  def check_rate(id, scale_ms, limit) do
    case Hammer.check_rate(id, scale_ms, limit) do
      {:allow, _count} -> :ok
      {:deny, _count} -> {:error, :exceeded_rate_limit}
    end
  end
end
