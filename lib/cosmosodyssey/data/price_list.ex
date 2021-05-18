defmodule Cosmosodyssey.Data.PriceList do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, []}
  @derive {Phoenix.Param, key: :id}
  schema "priceLists" do
    field :valid_until, :string
    has_many :routes, Cosmosodyssey.Data.Route
    timestamps()
  end

  def changeset(booking, attrs) do
    booking
    |> cast(attrs, [:id, :valid_until])
    |> validate_required([:id, :valid_until])
    |> unique_constraint(:id)
  end
end
