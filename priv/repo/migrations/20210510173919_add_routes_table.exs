defmodule Cosmosodyssey.Repo.Migrations.AddRoutesTable do
  use Ecto.Migration

  def change do
    create table(:routes, primary_key: false) do
      add :id, :string, primary_key: true
      add :dropoff_planet, :string
      add :pickup_planet, :string
      add :distance, :bigint
      add :price_list_id, references(:priceLists, type: :string, on_delete: :delete_all)
      timestamps()
      end
  end
end
