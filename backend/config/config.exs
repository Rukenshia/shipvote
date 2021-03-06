# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

config :phoenix, :json_library, Jason

config :backend, BackendWeb.Endpoint,
  live_view: [signing_salt: "SXGmFxy6zcy0csSKhKkORSf8c0"],
  basic_auth_password: "fantasma",
  instrumenters: [Appsignal.Phoenix.Instrumenter]

# Template settings for appsignal
config :phoenix, :template_engines,
  eex: Appsignal.Phoenix.Template.EExEngine,
  exs: Appsignal.Phoenix.Template.ExsEngine

# General application configuration
config :backend,
  ecto_repos: [Backend.Repo]

# Configures the endpoint
config :backend, BackendWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "SXGmFxy6zcy0csSKhKkORSf8c0/f0fljUa5jxfN45yPABRptNBj0ie4e9KbJHKpP",
  render_errors: [view: BackendWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Backend.PubSub, adapter: Phoenix.PubSub.PG2],
  metrics_api_key: "none"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

import_config "appsignal.exs"
