defmodule Backend.Repo.Migrations.AddChannelShipDisabled do
  use Ecto.Migration

  def change do
    alter table(:channel_ships) do
      add(:enabled, :boolean, default: true)
    end
  end
end
