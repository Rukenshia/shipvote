defmodule Backend.Repo.Migrations.AddOverlayPositionSetting do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :overlay_position, :string, default: "top_left"
    end
  end
end
