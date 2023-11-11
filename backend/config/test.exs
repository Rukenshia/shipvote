import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :backend, BackendWeb.Endpoint,
  http: [port: 4001],
  server: false

config :backend, Backend.Wows.BackgroundRefresh, disabled: true

# Print only warnings and errors during test
config :logger, level: :warn

config :backend, Backend.Twitch.Api, twitch_secret_key: "dGVzdA=="

# Configure your database
config :backend, Backend.Repo,
  username: "postgres",
  password: "postgres",
  database: "backend_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
