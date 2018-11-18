defmodule Backend.Stream.ChannelShip do
  use Ecto.Schema
  import Ecto.Changeset

  schema "channel_ships" do
    belongs_to(:channel, Backend.Stream.Channel)
    belongs_to(:ship, Backend.Wows.Warship)

    timestamps()
  end

  @doc false
  def changeset(channel_ship, attrs) do
    channel_ship
    |> cast(attrs, [:channel_id, :ship_id])
    |> validate_required([:channel_id, :ship_id])
  end
end
