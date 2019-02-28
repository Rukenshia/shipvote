defmodule Backend.Repo.Migrations.RemoveRestApi do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      remove(:enable_rest_api)
    end
  end

  def down do
  end
end
