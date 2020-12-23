defmodule BackendWeb.PageController do
  use Phoenix.Controller

  require Logger

  action_fallback BackendWeb.FallbackController

  use BackendWeb, :controller

  import Ecto.Query, only: [from: 2]

  alias Backend.Stream
  alias Backend.Stream.Channel
  alias Backend.Stream.Vote
  alias Backend.Stream.VotedShip
  alias Backend.Repo

  def index(conn, _params) do
    text(conn, "tbd")
  end

  def health(conn, _params) do
    text(conn, "#{Application.spec(:backend, :vsn)}_aws")
  end

  def loaderio(conn, _params) do
    text(conn, "loaderio-ab47bee856c880d39a24bce59211bcfd")
  end

  def metrics(conn, _params) do
    # 30 days
    compare_against_seconds = -30 * 24 * 3600
    date = NaiveDateTime.utc_now()
    baseline = NaiveDateTime.add(date, compare_against_seconds, :second)

    channels = Repo.one(from(p in Channel, select: count(1)))

    channels_growth =
      Repo.one(from(c in Channel, select: count(1), where: c.inserted_at > ^baseline))

    votes = Repo.one(from(p in Vote, select: count(1)))
    votes_growth = Repo.one(from(c in Vote, select: count(1), where: c.inserted_at > ^baseline))

    user_votes = Repo.one(from(p in VotedShip, select: count(1)))

    user_votes_growth =
      Repo.one(from(c in VotedShip, select: count(1), where: c.inserted_at > ^baseline))

    recent_votes =
      from(rv in Vote,
        where: rv.inserted_at > ^baseline,
        order_by: [desc: rv.id],
        limit: 10
      )
      |> Repo.all()
      |> Repo.preload([:channel, :votes])

    open_votes =
      from(ov in Vote,
        where: ov.status == "open",
        order_by: [asc: ov.id],
        limit: 10
      )
      |> Repo.all()
      |> Repo.preload([:channel, :votes])

    six_months_ago = NaiveDateTime.utc_now() |> NaiveDateTime.add(-60 * 60 * 24 * 180, :second)

    all_channels =
      Repo.all(Channel)
      |> Repo.preload(:votes)

    channels_most_votes =
      all_channels
      |> Enum.sort_by(fn v -> v.votes |> length() end, :desc)
      |> Enum.take(10)

    channels_no_recent_votes =
      all_channels
      |> Enum.filter(fn c ->
        case c.votes |> length() == 0 do
          true ->
            false

          false ->
            not Enum.any?(c.votes, fn v ->
              NaiveDateTime.compare(v.inserted_at, six_months_ago) == :gt
            end)
        end
      end)

    render(conn, "metrics.html",
      channels: channels,
      channels_most_votes: channels_most_votes,
      channels_no_recent_votes: channels_no_recent_votes,
      votes: votes,
      user_votes: user_votes,
      channels_growth: channels_growth,
      votes_growth: votes_growth,
      user_votes_growth: user_votes_growth,
      recent_votes: recent_votes,
      open_votes: open_votes
    )
  end

  def channel_metrics(conn, %{"id" => id}) do
    case Stream.get_channel(id) do
      %Channel{} = channel ->
        votes =
          from(v in Vote,
            where: v.channel_id == ^channel.id,
            order_by: [desc: v.id],
            limit: 50
          )
          |> Repo.all()
          |> Repo.preload([:votes])

        render(conn, "channel_metrics.html",
          channel: channel,
          votes: votes
        )

      nil ->
        conn
        |> BackendWeb.FallbackController.call({:error, :not_found})
    end
  end
end
