defmodule Cosmosodyssey.Data.Provider do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, []}
  @derive {Phoenix.Param, key: :id}
  schema "providers" do
    field :start_time, :string
    field :end_time, :string
    field :price, :float
    field :company, :string
    has_many :bookings, Cosmosodyssey.Data.Booking
    belongs_to :route, Cosmosodyssey.Data.Route, type: :string
    timestamps()
  end

  def changeset(booking, attrs) do
    booking
    |> cast(attrs, [:id, :start_time, :end_time, :price, :company])
    |> validate_required([:id, :start_time, :end_time, :price, :company])
    |> validate_number(:price, greater_than: -1)
    |> unique_constraint(:id)
  end
end
