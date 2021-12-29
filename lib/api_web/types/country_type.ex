defmodule APIWeb.CountryType do
  @moduledoc false

  use Absinthe.Schema.Notation

  object :country_bounds do
    field :north, non_null(:float)

    field :south, non_null(:float)

    field :east, non_null(:float)

    field :west, non_null(:float)
  end

  object :country do
    field :name, non_null(:string)

    field :code, non_null(:string)

    field :latitude, non_null(:float)

    field :longitude, non_null(:float)

    field :bounds, non_null(:country_bounds)
  end

  object :country_edge do
    @desc "The item at the end of the edge."
    field :node, :country
  end

  object :country_connection do
    @desc "Identifies the total count of items in the connection."
    field :total_count, non_null(:integer), resolve: &total_count/3

    @desc "A list of edges."
    field :edges, list_of(:country_edge), resolve: &edges/3
  end

  defp edges(countries, _args, _resolution) do
    {:ok,
     Enum.map(countries, fn country ->
       %{node: country}
     end)}
  end

  defp total_count(countries, _args, _resolution) do
    {:ok, Enum.count(countries)}
  end
end
