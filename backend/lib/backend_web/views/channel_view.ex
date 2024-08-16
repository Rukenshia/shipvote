defmodule BackendWeb.ChannelView do
  use BackendWeb, :view
  require Logger

  def index(%{channels: channels}) do
    %{data: channels |> Enum.map(fn c -> show(%{channel: c}) end)}
  end

  def show(%{channel: channel}) do
    %{
      data:
        %{
          id: channel.id,
          wows_username: channel.wows_username,
          wows_account_id: channel.wows_account_id,
          wows_realm: channel.wows_realm,
          ships: []
        }
        |> render_ships(channel)
    }
  end

  def show(%{channel: channel, recent_ships: recent_ships}) do
    %{
      data:
        %{
          id: channel.id,
          wows_username: channel.wows_username,
          wows_account_id: channel.wows_account_id,
          wows_realm: channel.wows_realm,
          ships: [],
          recent_ships: recent_ships
        }
        |> render_ships(channel)
    }
  end

  def show_public(%{channel: channel}) do
    %{
      data:
        %{
          id: channel.id,
          ships: []
        }
        |> render_ships(channel)
    }
  end

  defp render_ships(data, channel) do
    if Ecto.assoc_loaded?(channel.ships) and
         Enum.all?(channel.ships, fn s -> Ecto.assoc_loaded?(s.ship) end) do
      data
      |> Map.put(
        :ships,
        Enum.map(channel.ships, fn s ->
          BackendWeb.WarshipView.render("warship.json", %{warship: s.ship})
          |> Map.put(:enabled, s.enabled)
        end)
      )
    else
      data
    end
  end
end
