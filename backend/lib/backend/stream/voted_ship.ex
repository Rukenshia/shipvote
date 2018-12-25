defmodule Backend.Stream.VotedShip do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stream_voted_ships" do
    field(:user_id, :string)

    belongs_to(:vote, Backend.Stream.Vote)
    belongs_to(:ship, Backend.Wows.Warship)

    timestamps()
  end

  @doc false
  def changeset(voted_ship, attrs) do
    voted_ship
    |> cast(attrs, [:vote_id, :ship_id, :user_id])
    |> validate_required([:vote_id, :ship_id, :user_id])
    |> unique_constraint(:user_id, name: :stream_voted_ships_vote_id_user_id_index)
  end
end
