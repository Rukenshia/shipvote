defmodule BackendWeb.Router do
  use BackendWeb, :router
  require Logger

  pipeline :api do
    plug(:accepts, ["json"])
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

    get("/_health", PageController, :health)
  end

  scope "/api", BackendWeb do
    pipe_through(:api)

    resources("/warships", WarshipController, except: [:new, :edit])

    scope("/channels/:id") do
      pipe_through(:verify_jwt)

      get("/", ChannelController, :show_public_info)

      get("/votes", VoteController, :index)
      get("/votes/:vote_id", VoteController, :show)
      post("/votes/:vote_id/submit", VoteController, :vote_for_ship)

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
