defmodule Backend.Stream.Channel do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Backend.Stream.{ChannelShip, Vote}
  alias Backend.Repo

  schema "channels" do
    field(:wows_username, :string)
    field(:wows_account_id, :integer)
    field(:wows_realm, :string)

    field(:overlay_position, Ecto.Enum, values: [:top_left, :top_right, :bottom_left, :bottom_right], default: :top_left)

    field(:vote_status_delay, :integer, virtual: true)
    field(:vote_progress_delay, :integer, virtual: true)

    has_many(:ships, Backend.Stream.ChannelShip)
    has_many(:votes, Backend.Stream.Vote)
    timestamps()
  end

  def most_recent_vote(channel) do
    from(v in Vote, where: v.channel_id == ^channel.id, order_by: [desc: v.inserted_at], limit: 1)
    |> Repo.one()
  end

  def most_recently_used_ships(channel) do
    case most_recent_vote(channel) do
      nil -> []
      vote -> vote.ships
    end
  end

  @doc false
  def changeset(channel, attrs) do
    channel
    |> cast(attrs, [:id, :wows_username, :wows_account_id, :wows_realm, :overlay_position])
    |> validate_required([:id, :wows_username, :wows_account_id, :wows_realm, :overlay_position])
    |> validate_inclusion(:wows_realm, ["ru", "eu", "na", "asia"])
    |> unique_constraint(:id, name: :channels_pkey)
  end
end
