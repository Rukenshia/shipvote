defmodule Backend.Repo.Migrations.AddVoteScheduledEndTimestamp do
  use Ecto.Migration

  def change do
    alter table(:stream_votes) do
      add(:scheduled_end, :utc_datetime, null: true)
    end
  end
end
