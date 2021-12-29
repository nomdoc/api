defmodule APIWeb.CountriesResolver do
  @moduledoc false

  use APIWeb, :resolver

  object :countries_queries do
    field :all_countries, non_null(:country_connection), resolve: &all_countries/2
  end

  defp all_countries(_args, _resolution) do
    {:ok, Countries.list_all()}
  end
end
