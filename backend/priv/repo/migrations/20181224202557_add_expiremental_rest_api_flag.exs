defmodule Backend.Repo.Migrations.AddExpirementalRestApiFlag do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add(:enable_rest_api, :boolean, default: true)
    end
  end
end
