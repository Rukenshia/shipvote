defmodule Backend.Stream.ChannelShip do
  use Ecto.Schema
  import Ecto.Changeset

  schema "channel_ships" do
    belongs_to(:channel, Backend.Stream.Channel)
    has_one(:ship, Backend.Wows.Warship)

    field(:enabled, :boolean, default: true)

    timestamps()
  end

  @doc false
  def changeset(channel_ship, attrs) do
    channel_ship
    |> cast(attrs, [:channel_id, :ship_id, :enabled])
    |> validate_required([:channel_id, :ship_id, :enabled])
    |> foreign_key_constraint(:ship_id)
    |> unique_constraint(:ship_id, name: :channel_ships_channel_id_ship_id_index)
  end

  @doc false
  def status_changeset(channel_ship, attrs) do
    channel_ship
    |> cast(attrs, [:enabled])
    |> validate_required([:enabled])
  end
end
