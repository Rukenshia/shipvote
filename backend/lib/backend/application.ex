defmodule Backend.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Backend.Repo, []),
      # Start the endpoint when the application starts
      supervisor(BackendWeb.Endpoint, []),
      # Start your own worker by calling: Backend.Worker.start_link(arg1, arg2, arg3)
      # worker(Backend.Worker, [arg1, arg2, arg3]),
      worker(Backend.Wows.BackgroundRefresh, []),
      Supervisor.child_spec({ConCache, [name: :ships_cache, ttl_check_interval: false]},
        id: :ships_cache
      ),
      Supervisor.child_spec({ConCache, [name: :vote_cache, ttl_check_interval: false]},
        id: :vote_cache
      ),
      Supervisor.child_spec({ConCache, [name: :rest_vote_cache, ttl_check_interval: false]},
        id: :rest_vote_cache
      )
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Backend.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BackendWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
