defmodule BackendWeb.ChannelShipView do
  use BackendWeb, :view
  alias BackendWeb.ChannelShipView

  def render("index.json", %{channel_ships: channel_ships}) do
    %{data: render_many(channel_ships, ChannelShipView, "channel_ship.json")}
  end

  def render("channel_ship.json", %{channel_ship: channel_ship}) do
    BackendWeb.WarshipView.render("warship.json", %{warship: channel_ship.ship})
  end
end
