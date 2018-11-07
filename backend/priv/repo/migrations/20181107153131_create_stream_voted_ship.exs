defmodule Backend.Repo.Migrations.CreateStreamVotedShip do
  use Ecto.Migration

  def change do
    create table(:stream_voted_ships) do
      add(:vote_id, references(:stream_votes))
      add(:ship_id, references(:warships))
      add(:user_id, :string)

      timestamps()
    end

    create(unique_index(:stream_voted_ships, [:vote_id, :user_id]))
    create(index(:stream_voted_ships, [:vote_id]))
  end
end
