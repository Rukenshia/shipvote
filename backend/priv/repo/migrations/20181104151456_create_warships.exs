defmodule Backend.Repo.Migrations.CreateWarships do
  use Ecto.Migration

  def change do
    create table(:warships) do
      add(:name, :string)
      add(:tier, :integer)
      add(:nation, :string)
      add(:type, :string)
      add(:image, :string)
      add(:premium, :boolean, default: false, null: false)

      timestamps()
    end
  end
end
