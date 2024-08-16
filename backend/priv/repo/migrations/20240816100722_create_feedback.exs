defmodule Backend.Repo.Migrations.CreateFeedback do
  use Ecto.Migration

  def change do
    create table(:feedback) do
      add :message, :text
      add :channel_id, references(:channels, on_delete: :nothing)

      timestamps()
    end

    create index(:feedback, [:channel_id])
  end
end
