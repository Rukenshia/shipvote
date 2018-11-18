defmodule BackendWeb.Router do
  use BackendWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", BackendWeb do
    get("/privacy-policy", NoticeController, :privacy_policy)
  end

  scope "/api", BackendWeb do
    pipe_through(:api)

    resources("/warships", WarshipController, except: [:new, :edit])

    resources("/channels", ChannelController, except: [:new, :edit]) do
      get("/ships", ChannelShipController, :get_channel_ships)
    end
  end
end
