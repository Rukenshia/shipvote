defmodule Backend.Stream.Vote do
  use Ecto.Schema
  import Ecto.Changeset

  schema "stream_votes" do
    belongs_to(:channel, Backend.Stream.Channel)
    field(:ships, {:array, :integer})
    field(:status, :string)
    field(:scheduled_end, :utc_datetime)

    has_many(:votes, Backend.Stream.VotedShip)

    timestamps()
  end

  @doc false
  def changeset(vote, attrs) do
    vote
    |> cast(attrs, [:channel_id, :ships, :status, :scheduled_end, :inserted_at])
    |> validate_required([:channel_id, :ships, :status])
  end

  @doc false
  def status_changeset(vote, attrs) do
    vote
    |> cast(attrs, [:status])
    |> validate_required([:status])
    |> validate_inclusion(:status, ["open", "closed"])
  end
end
