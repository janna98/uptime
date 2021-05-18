defmodule Cosmosodyssey.Data.Route do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, []}
  @derive {Phoenix.Param, key: :id}
  schema "routes" do
    field :dropoff_planet, :string
    field :pickup_planet, :string
    field :distance, :integer
    has_many :providers, Cosmosodyssey.Data.Provider
    belongs_to :price_list, Cosmosodyssey.Data.PriceList, type: :string
    timestamps()
  end

  def changeset(route, attrs) do
    route
    |> cast(attrs, [:id, :dropoff_planet, :pickup_planet, :distance])
    |> validate_required([:id, :dropoff_planet, :pickup_planet, :distance])
    |> validate_number(:distance, greater_than: -1)
    |> unique_constraint(:id)
  end
end
