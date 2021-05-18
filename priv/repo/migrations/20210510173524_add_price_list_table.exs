defmodule Cosmosodyssey.Repo.Migrations.AddPriceListTable do
  use Ecto.Migration

  def change do
    create table(:priceLists, primary_key: false) do
      add :id, :string, primary_key: true
      add :valid_until, :string
      timestamps()
    end
  end
end
