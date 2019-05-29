defmodule Backend.Stream.Channel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "channels" do
    field(:wows_username, :string)
    field(:wows_account_id, :integer)
    field(:wows_realm, :string)

    field(:vote_status_delay, :integer, virtual: true)
    field(:vote_progress_delay, :integer, virtual: true)

    has_many(:ships, Backend.Stream.ChannelShip)
    timestamps()
  end

  @doc false
  def changeset(channel, attrs) do
    channel
    |> cast(attrs, [:id, :wows_username, :wows_account_id, :wows_realm])
    |> validate_required([:id, :wows_username, :wows_account_id, :wows_realm])
    |> validate_inclusion(:wows_realm, ["ru", "eu", "na", "asia"])
    |> unique_constraint(:id, name: :channels_pkey)
  end
end
