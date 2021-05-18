# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :cosmosodyssey,
  ecto_repos: [Cosmosodyssey.Repo]

# Configures the endpoint
config :cosmosodyssey, CosmosodysseyWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "l+TYP9MxIIV5mpwgf4Tdx/7AF5rCy7Xz8wLl7+lxVvkJ33iCqyjjN8Lu901ZF1YO",
  render_errors: [view: CosmosodysseyWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Cosmosodyssey.PubSub,
  live_view: [signing_salt: "hano81mGotKA2Yn7QaSiKFpio1DKVecg"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

config :cosmosodyssey, Cosmosodyssey.Guardian,
       issuer: "cosmosodyssey",
       secret_key: "qIOlRA9N/unNA5LTRwgf6QUfnH6ZvEyRd8Qv87wl3l2KbU6WK3dd66j1jfb8LnxY"
