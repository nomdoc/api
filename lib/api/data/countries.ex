defmodule API.Countries do
  @moduledoc false

  alias API.Country

  @countries Countries.all()
             |> Enum.reject(fn country -> is_binary(country.dissolved_on) end)
             |> Enum.map(fn country ->
               %Country{
                 name:
                   if country.name == "eSwatini" do
                     "Eswatini"
                   else
                     country.name
                   end,
                 status:
                   if country.alpha2 == "MY" do
                     :supported
                   else
                     :unsupported
                   end,
                 code: String.downcase(country.alpha2),
                 latitude: country.geo.latitude,
                 longitude: country.geo.longitude,
                 bounds: %{
                   north: country.geo.bounds.northeast.lat,
                   south: country.geo.bounds.southwest.lat,
                   east: country.geo.bounds.northeast.lng,
                   west: country.geo.bounds.southwest.lng
                 }
               }
             end)

  @spec list_all() :: [Country.t()]
  def list_all() do
    @countries
  end

  @spec get_by(Keyword.t()) :: nil | Country.t()
  def get_by(clauses) do
    Enum.find(@countries, fn country ->
      Enum.map(clauses, fn {key, val} ->
        Map.get(country, key) == val
      end)
      |> Enum.all?()
    end)
  end

  @spec valid?(Keyword.t()) :: boolean()
  def valid?(clauses) do
    case get_by(clauses) do
      %Country{} -> true
      nil -> false
    end
  end
end
