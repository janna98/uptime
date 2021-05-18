defmodule Cosmosodyssey.Repo.Migrations.AddBookingsTable do
  use Ecto.Migration

  def change do
    create table(:bookings) do
      add :status, :string, default: "open"
      add :travel_time, :integer
      add :user_id, references(:users)
      add :provider_id, references(:providers, type: :string, on_delete: :delete_all)
      timestamps()
    end
  end
end
