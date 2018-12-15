defmodule BackendWeb.ChannelShipController do
  use BackendWeb, :controller

  import Ecto.Query, only: [from: 2]
  alias Backend.Stream.ChannelShip
  alias Backend.Repo

  action_fallback(BackendWeb.FallbackController)

  def update_channel_ship_status(conn, %{
        "id" => channel_id,
        "ship_id" => ship_id,
        "enabled" => enabled
      })
      when is_boolean(enabled) do
    with %ChannelShip{} = ship <-
           from(s in ChannelShip, where: s.channel_id == ^channel_id and s.ship_id == ^ship_id)
           |> Repo.one() do
      ship
      |> ChannelShip.status_changeset(%{enabled: enabled})
      |> Repo.update!()

      conn
      |> put_status(200)
      |> json(%{ok: true})
    else
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{ok: false, message: "ChannelShip not found"})
    end
  end

  def update_channel_ship_status(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{ok: false, message: "Bad Request"})
  end
end
