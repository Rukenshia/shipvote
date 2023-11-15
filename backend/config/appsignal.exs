import Config

config :appsignal, :config,
  active: true,
  otp_app: :backend,
  name: "shipvote",
  env: Mix.env()
