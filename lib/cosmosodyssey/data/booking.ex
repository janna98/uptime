defmodule Cosmosodyssey.Data.Booking do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bookings" do
    field :status, :string
    field :travel_time, :integer
    belongs_to :user, Cosmosodyssey.Accounts.User
    belongs_to :provider, Cosmosodyssey.Data.Provider, type: :string
    timestamps()
  end

  def changeset(booking, attrs) do
    booking
    |> cast(attrs, [:status, :travel_time])
    |> validate_required([:status, :travel_time])
  end
end
