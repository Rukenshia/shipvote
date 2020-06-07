defmodule Backend.Repo.Migrations.AddStreamVotesChannelIdIndex do
  use Ecto.Migration

  def change do
    create index(:stream_votes, [:channel_id])
  end
end
