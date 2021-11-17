defmodule API.ReservedHandleName do
  @moduledoc false

  @list API.ReservedHandleNameLoader.load()

  @spec all :: [binary()]
  def all() do
    @list
  end

  @spec ensure_available(binary()) :: :ok | {:error, :handle_name_reserved}
  def ensure_available(handle_name) do
    if Enum.member?(@list, handle_name),
      do: {:error, :handle_name_reserved},
      else: :ok
  end
end
