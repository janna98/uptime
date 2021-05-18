defmodule Cosmosodyssey.Repo.Migrations.AddProvidersTable do
  use Ecto.Migration

  def change do
    create table(:providers, primary_key: false) do
      add :id, :string, primary_key: true
      add :start_time, :string
      add :end_time, :string
      add :price, :float
      add :company, :string
      add :route_id, references(:routes, type: :string, on_delete: :delete_all)
      timestamps()
    end
  end
end
