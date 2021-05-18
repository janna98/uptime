defmodule Cosmosodyssey.Repo do
  use Ecto.Repo,
    otp_app: :cosmosodyssey,
    adapter: Ecto.Adapters.Postgres
end
