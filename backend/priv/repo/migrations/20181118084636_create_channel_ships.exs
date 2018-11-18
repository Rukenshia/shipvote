defmodule Backend.Repo.Migrations.CreateChannelShips do
  use Ecto.Migration

  def change do
    create table(:channel_ships) do
      add(:channel_id, references(:channels, on_delete: :delete_all))
      add(:ship_id, references(:warships, on_delete: :delete_all))

      timestamps()
    end

    create(index(:channel_ships, [:channel_id]))
    create(index(:channel_ships, [:ship_id]))
  end
end
