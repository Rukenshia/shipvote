defmodule Backend.Application do
  require Logger
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    features = get_features()

    # Define workers and child supervisors to be supervised
    children =
      [
        # Start the Ecto repository
        supervisor(Backend.Repo, []),
        # Start the endpoint when the application starts
        supervisor(BackendWeb.Endpoint, []),
        # Start your own worker by calling: Backend.Worker.start_link(arg1, arg2, arg3)
        # worker(Backend.Worker, [arg1, arg2, arg3]),
        Supervisor.child_spec(
          {ConCache, [name: :ships_cache, ttl_check_interval: 500, global_ttl: 5000]},
          id: :ships_cache
        ),
        Supervisor.child_spec(
          {ConCache, [name: :vote_cache, ttl_check_interval: 500, global_ttl: 5000]},
          id: :vote_cache
        ),
        Supervisor.child_spec(
          {ConCache, [name: :rest_vote_cache, ttl_check_interval: 500, global_ttl: 5000]},
          id: :rest_vote_cache
        ),
        Supervisor.child_spec(
          {ConCache, [name: :channel_cache, ttl_check_interval: 500, global_ttl: 5000]},
          id: :channel_cache
        ),
        BackendWeb.Telemetry,
      ] ++ features

	  :telemetry.attach(
      "appsignal-ecto",
      [:backend, :repo, :query],
      &Appsignal.Ecto.handle_event/4,
      nil
    )

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Backend.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Enable features based on environment variables
  #
  # ENABLE_BACKGROUND_REFRESH: Enables the BackgroundRefresh feature (refresh Warships periodically)
  # ENABLE_CHANNEL_SHIP_REFRESH: Enables the ChannelShipRefresh feature (refreshes ChannelShip periodically)
  def get_features() do
    import Supervisor.Spec

    background_refresh = System.get_env("ENABLE_BACKGROUND_REFRESH")
    channel_ship_refresh = System.get_env("ENABLE_CHANNEL_SHIP_REFRESH")

    Logger.warn("Features")

    features =
      case background_refresh do
        e when e in ["1", "true"] ->
          Logger.warn("\tBackgroundRefresh: enabled")
          [worker(Backend.Wows.BackgroundRefresh, [])]

        _ ->
          Logger.warn("\tBackgroundRefresh: disabled")
          []
      end

    features =
      case channel_ship_refresh do
        e when e in ["1", "true"] ->
          Logger.warn("\tChannelShipRefresh: enabled")
          features ++ [worker(Backend.Stream.ChannelShipRefresh, [])]

        _ ->
          Logger.warn("\tChannelShipRefresh: disabled")
          features
      end

    features
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BackendWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
