defmodule BackendWeb.PageController do
  require Logger

  use BackendWeb, :controller

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

    channels = Repo.all(Channel)
    votes = Repo.all(Vote)
    user_votes = Repo.all(VotedShip)

    channels_growth = channels
      |> Enum.filter(fn v -> baseline < v.inserted_at end)
      |> length

    votes_growth = votes
      |> Enum.filter(fn v -> baseline < v.inserted_at end)
      |> length

    user_votes_growth = user_votes
      |> Enum.filter(fn v -> baseline < v.inserted_at end)
      |> length

    render(conn, "metrics.html",
      channels: channels |> length,
      votes: votes |> length,
      user_votes: user_votes |> length,
      channels_growth: channels_growth,
      votes_growth: votes_growth,
      user_votes_growth: user_votes_growth
    )
  end
end
