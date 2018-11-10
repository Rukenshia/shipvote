defmodule Backend.Repo.Migrations.CreateStreamVotes do
  use Ecto.Migration

  def change do
    create table(:stream_votes) do
      add(:channel_id, :integer)
      add(:ships, {:array, :bigint})
      add(:status, :string)

      timestamps()
    end
  end
end
