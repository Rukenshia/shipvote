import Config

config :appsignal, :config,
  otp_app: :backend,
  name: "shipvote",
  env: Mix.env(),
  active: true
