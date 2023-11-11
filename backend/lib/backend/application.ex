defmodule Backend.Application do
  require Logger
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    features = get_features()

    # Define workers and child supervisors to be supervised
    children =
      [
        # Start the Ecto repository
        Supervisor.child_spec({Backend.Repo, []}, id: :backend_repo),
        # Start the endpoint when the application starts
        Supervisor.child_spec({BackendWeb.Endpoint, []}, id: :backend_web),
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
          {ConCache, [name: :channel_cache, ttl_check_interval: 500, global_ttl: 5000]},
          id: :channel_cache
        ),
        Supervisor.child_spec(
          {ConCache, [name: :vote_progress_cache, ttl_check_interval: false]},
          id: :vote_progress_cache
        ),
        BackendWeb.Telemetry,
        Supervisor.child_spec(
          {Backend.Stream.BackgroundVoteClose, []},
          id: :background_vote_close
        ),
        Supervisor.child_spec(
          {Backend.Twitch.VoteProgress, []},
          id: :vote_progress
        )
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
    background_refresh = System.get_env("ENABLE_BACKGROUND_REFRESH")
    channel_ship_refresh = System.get_env("ENABLE_CHANNEL_SHIP_REFRESH")

    Logger.warning("Features")

    features =
      case background_refresh do
        e when e in ["1", "true"] ->
          Logger.warning("\tBackgroundRefresh: enabled")

          [
            Supervisor.child_spec({Backend.Wows.BackgroundRefresh, []},
              id: :background_refresh
            )
          ]

        _ ->
          Logger.warning("\tBackgroundRefresh: disabled")
          []
      end

    features =
      case channel_ship_refresh do
        e when e in ["1", "true"] ->
          Logger.warning("\tChannelShipRefresh: enabled")

          features ++
            [
              Supervisor.child_spec({Backend.Wows.ChannelShipRefresh, []},
                id: :channel_ship_refresh
              )
            ]

        _ ->
          Logger.warning("\tChannelShipRefresh: disabled")
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
