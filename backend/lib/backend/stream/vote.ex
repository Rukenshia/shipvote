defmodule Backend.Stream.Vote do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stream_votes" do
    field(:channel_id, :integer)
    field(:ships, {:array, :integer})
    field(:status, :string)

    has_many(:votes, Backend.Stream.VotedShip)

    timestamps()
  end

  @doc false
  def changeset(vote, attrs) do
    vote
    |> cast(attrs, [:channel_id, :ships, :status])
    |> validate_required([:channel_id, :ships, :status])
  end
end
