# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
import Config

config :phoenix, :json_library, Jason

config :esbuild,
  version: "0.12.18",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets --external:/fonts/* --external:/images/* --external:/videos/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :backend, BackendWeb.Endpoint,
  live_view: [signing_salt: "SXGmFxy6zcy0csSKhKkORSf8c0"],
  basic_auth_password: "fantasma"

config :backend, Backend.VoteProgress, enabled: true

# General application configuration
config :backend,
  ecto_repos: [Backend.Repo]

# Configures the endpoint
config :backend, BackendWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "SXGmFxy6zcy0csSKhKkORSf8c0/f0fljUa5jxfN45yPABRptNBj0ie4e9KbJHKpP",
  render_errors: [view: BackendWeb.ErrorView, accepts: ~w(html json)],
  metrics_api_key: "none"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

import_config "appsignal.exs"
