defmodule API.Pagination do
  @moduledoc false

  @type t :: %__MODULE__{
          edges: list(map()),
          page_info: %{
            end_cursor: binary(),
            has_next_page: boolean(),
            has_previous_page: boolean(),
            start_cursor: binary()
          },
          metadata: map()
        }
  @enforce_keys [:edges, :page_info]
  defstruct edges: nil, page_info: nil, metadata: %{}

  @spec put_metadata(t(), atom() | binary(), term()) :: t()
  def put_metadata(%__MODULE__{} = pagination, key, value) do
    put_in(pagination, [Access.key!(:metadata), key], value)
  end
end
