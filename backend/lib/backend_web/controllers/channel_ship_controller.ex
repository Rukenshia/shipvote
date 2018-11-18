defmodule BackendWeb.ChannelShipController do
  use BackendWeb, :controller

  alias Backend.Stream
  alias Backend.Stream.ChannelShip
  alias BackendWeb.Router.Helpers, as: Routes

  action_fallback(BackendWeb.FallbackController)

  def index(conn, %{channel_id: channel_id}) do
    channel_ships = Stream.list_channel_ships(channel_id)
    render(conn, "index.json", channel_ships: channel_ships)
  end
end
