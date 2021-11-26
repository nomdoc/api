defmodule API.RateLimiterProvider do
  @moduledoc false

  @callback check_rate(binary(), integer(), integer()) :: :ok | {:error, :exceeded_rate_limit}
end
