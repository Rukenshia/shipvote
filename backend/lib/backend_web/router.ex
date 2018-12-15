defmodule BackendWeb.Router do
  use BackendWeb, :router
  require Logger

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :verify_jwt do
    plug(Backend.Auth.Twitch)
  end

  scope "/", BackendWeb do
    get("/privacy-policy", NoticeController, :privacy_policy)
    get("/getting-started", NoticeController, :getting_started)
  end

  scope "/api", BackendWeb do
    pipe_through(:api)

    resources("/warships", WarshipController, except: [:new, :edit])

    scope "/settings" do
      pipe_through(:verify_jwt)

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
