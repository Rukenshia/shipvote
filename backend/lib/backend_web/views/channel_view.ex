defmodule BackendWeb.ChannelView do
  use BackendWeb, :view
  alias BackendWeb.ChannelView

  def render("index.json", %{channels: channels}) do
    %{data: render_many(channels, ChannelView, "channel.json")}
  end

  def render("show.json", %{channel: channel}) do
    %{data: render_one(channel, ChannelView, "channel.json")}
  end

  def render("channel.json", %{channel: channel}) do
    %{
      id: channel.id,
      wows_username: channel.wows_username,
      wows_account_id: channel.wows_account_id,
      wows_realm: channel.wows_realm,
      ships: []
    }
    |> render_ships(channel)
  end

  defp render_ships(data, channel) do
    if Ecto.assoc_loaded?(channel.ships) and
         Enum.all?(channel.ships, fn s -> Ecto.assoc_loaded?(s.ship) end) do
      data
      |> Map.put(
        :ships,
        BackendWeb.WarshipView.render("warships.json", %{
          warships: Enum.map(channel.ships, fn s -> s.ship end)
        })
      )
    else
      data
    end
  end
end
