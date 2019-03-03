defmodule Backend.Repo.Migrations.CascadeWarshipDeletion do
  use Ecto.Migration

  def change do
    drop constraint(:stream_voted_ships, "stream_voted_ships_ship_id_fkey")

    alter table(:stream_voted_ships) do
      modify(:ship_id, references(:warships, on_delete: :delete_all))
    end
  end
end
