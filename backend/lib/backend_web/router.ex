defmodule BackendWeb.Router do
  use BackendWeb, :router
  import Plug.BasicAuth
  import Phoenix.LiveDashboard.Router

  @basic_auth_password Application.compile_env(:backend, BackendWeb.Endpoint)[
                         :basic_auth_password
                       ]

  require Logger

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :browser do
    plug(:accepts, ["html"])
  end

  pipeline :admin do
    plug :basic_auth, username: "elsenor", password: @basic_auth_password
  end

  pipeline :verify_jwt do
    plug(Backend.Auth.Twitch)
  end

  pipeline :broadcaster do
    plug(Backend.Auth.Twitch, :require_broadcaster)
  end

  scope "/", BackendWeb do
    get("/privacy-policy", NoticeController, :privacy_policy)
    get("/getting-started", NoticeController, :getting_started)

    scope "/metrics" do
      pipe_through([:browser, :admin])

      get("/", PageController, :metrics)
      get("/channels/:id", PageController, :channel_metrics)
      live_dashboard "/dashboard", metrics: BackendWeb.Telemetry
    end

    get("/_health", PageController, :health)
    get("/loaderio-ab47bee856c880d39a24bce59211bcfd", PageController, :loaderio)
  end

  scope "/api", BackendWeb do
    pipe_through(:api)

    resources("/warships", WarshipController, except: [:new, :edit])

    get("/votes", VoteController, :all)

    scope("/channels/:id") do
      get("/", ChannelController, :show_public_info)

      get("/votes", VoteController, :index)

      scope "/votes/:vote_id" do
        pipe_through(:verify_jwt)

        get("/", VoteController, :show)
        post("/submit", VoteController, :vote_for_ship)
      end

      scope "/" do
        pipe_through(:broadcaster)

        post("/votes", VoteController, :create)
        patch("/votes/:vote_id/status", VoteController, :set_status)
      end
    end

    scope "/settings" do
      pipe_through([:verify_jwt, :broadcaster])

      resources("/channels", ChannelController, except: [:index, :new, :edit])

      put(
        "/channels/:id/ships/:ship_id/enabled",
        ChannelShipController,
        :update_channel_ship_status
      )
    end

    get("/_metrics/channels", ChannelController, :index)
  end
end
