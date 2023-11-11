defmodule Backend.Wows.Warship do
  use Ecto.Schema
  import Ecto.Changeset

  schema "warships" do
    field(:name, :string)
    field(:type, :string)
    field(:nation, :string)
    field(:image, :string)
    field(:premium, :boolean, default: false)
    field(:tier, :integer)

    timestamps()
  end

  @doc false
  def changeset(warship, attrs) do
    warship
    |> cast(attrs, [:name, :tier, :premium, :nation, :type, :image])
    |> validate_required([:name, :tier, :premium])
  end

  def changeset_from_api(warship, data) do
    warship
    |> changeset(%{
      name: data["name"],
      tier: data["tier"],
      premium:
        data["is_premium"] || data["is_special"] ||
          (data["tier"] != 10 && Kernel.map_size(data["next_ships"]) == 0),
      nation: data["nation"],
      type: data["type"],
      image: data["images"]["small"]
    })
  end
end
