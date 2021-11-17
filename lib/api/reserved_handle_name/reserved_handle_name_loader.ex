defmodule API.ReservedHandleNameLoader do
  @moduledoc false

  @spec load() :: [binary()]
  def load() do
    data_path("/data.json")
    |> File.read!()
    |> Jason.decode!(keys: :atoms!)
  end

  defp data_path(path) do
    Path.join([:code.priv_dir(:api), "reserved_handle_name", path])
  end
end
