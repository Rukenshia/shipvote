defmodule BackendWeb.PageController do
  require Logger

  use BackendWeb, :controller

  import Ecto.Query, only: [from: 2]

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
    compare_against_seconds = - 30 * 24 * 3600 # 30 days
    date = NaiveDateTime.utc_now()
    baseline = NaiveDateTime.add(date, compare_against_seconds, :second)

    channels = Repo.one(from p in Channel, select: count(1))
    channels_growth = Repo.one(from c in Channel, select: count(1), where: c.inserted_at > ^baseline)

    votes = Repo.one(from p in Vote, select: count(1))
    votes_growth = Repo.one(from c in Vote, select: count(1), where: c.inserted_at > ^baseline)

    user_votes = Repo.one(from p in VotedShip, select: count(1))
    user_votes_growth = Repo.one(from c in VotedShip, select: count(1), where: c.inserted_at > ^baseline)

    recent_votes = from(rv in Vote,
      where: rv.inserted_at > ^baseline,
      order_by: [desc: rv.id],
      limit: 10,
    )
      |> Repo.all()
      |> Repo.preload([:channel, :votes])

    open_votes = from(ov in Vote,
        where: ov.status == "open",
        order_by: [asc: ov.id],
        limit: 10,
      )
        |> Repo.all()
        |> Repo.preload([:channel, :votes])

    render(conn, "metrics.html",
      channels: channels,
      votes: votes,
      user_votes: user_votes,
      channels_growth: channels_growth,
      votes_growth: votes_growth,
      user_votes_growth: user_votes_growth,
      recent_votes: recent_votes,
      open_votes: open_votes,
    )
  end
end
