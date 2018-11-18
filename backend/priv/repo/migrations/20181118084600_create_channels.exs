defmodule Backend.Repo.Migrations.CreateChannels do
  use Ecto.Migration

  def change do
    create table(:channels) do
      add(:wows_username, :string)
      add(:wows_account_id, :bigint)
      add(:wows_realm, :string)

      timestamps()
    end
  end
end
