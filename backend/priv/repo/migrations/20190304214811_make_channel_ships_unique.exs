defmodule Backend.Repo.Migrations.MakeChannelShipsUnique do
  use Ecto.Migration

  def change do
    create(
      unique_index(:channel_ships, [:channel_id, :ship_id],
        name: :channel_ships_channel_id_ship_id_index
      )
    )
  end
end
