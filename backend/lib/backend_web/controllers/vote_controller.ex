defmodule BackendWeb.VoteController do
  use BackendWeb, :controller
  require Logger

  alias Backend.Repo
  alias Backend.Stream
  alias Backend.Stream.Vote
  alias Backend.Stream.VotedShip

  import Ecto.Query, only: [from: 2]

  ## TODO
  ## * Improve caching, migrate to single cache and pick results
  ## * Changeset error handling for duplicate vote

  def all(conn, %{"status" => status})
      when status == "open" do
    votes =
      ConCache.get_or_store(:vote_cache, "all_status_#{status}", fn ->
        votes =
          from(p in Backend.Stream.Vote,
            where: p.status == ^status
          )
          |> Repo.all()
          |> Repo.preload(:votes)

        %ConCache.Item{value: votes, ttl: :timer.seconds(60)}
      end)

    conn
    |> render("votes.json", %{votes: votes})
  end

  def index(conn, %{"id" => channel_id, "status" => status})
      when status == "open" or status == "closed" do
    votes =
      ConCache.get_or_store(:vote_cache, "index_status_#{channel_id}_#{status}", fn ->
        votes =
          from(p in Backend.Stream.Vote,
            where: p.channel_id == ^channel_id and p.status == ^status,
            order_by: [asc: :updated_at]
          )
          |> Repo.all()
          |> Repo.preload(:votes)

        %ConCache.Item{value: votes, ttl: :timer.seconds(60)}
      end)

    if status == "closed" do
      conn
      |> render("votes.json", %{votes: Enum.take(votes, -5)})
    else
      conn
      |> render("votes.json", %{votes: votes})
    end
  end

  def index(conn, %{"id" => channel_id}) do
    votes =
      ConCache.get_or_store(:vote_cache, "index_#{channel_id}", fn ->
        votes =
          from(p in Backend.Stream.Vote,
            where: p.channel_id == ^channel_id
          )
          |> Repo.all()
          |> Repo.preload(:votes)

        %ConCache.Item{value: votes, ttl: :timer.seconds(60)}
      end)

    conn
    |> render("votes.json", %{votes: votes})
  end

  def show(conn, %{"id" => _channel_id, "vote_id" => vote_id, "full" => "false"}) do
    vote_id = String.to_integer(vote_id)

    vote = Stream.get_cached_vote(vote_id)

    case vote do
      %Vote{} = vote ->
        conn |> render("show.slim.json", %{vote: vote})

      :not_found ->
        conn |> put_status(:not_found) |> json(%{ok: false, message: "Not found"})
    end
  end

  def show(conn, %{"id" => _channel_id, "vote_id" => vote_id}) do
    vote_id = String.to_integer(vote_id)

    vote = Stream.get_cached_vote(vote_id)

    case vote do
      %Vote{} = vote ->
        conn |> render("show.json", %{vote: vote})

      :not_found ->
        conn |> put_status(:not_found) |> json(%{ok: false, message: "Not found"})
    end
  end

  def create(conn, %{"id" => channel_id, "vote" => attrs}) do
    attrs = attrs |> Map.merge(%{"channel_id" => channel_id})

    case %Vote{}
         |> Vote.changeset(attrs)
         |> Repo.insert() do
      {:ok, vote} ->
        ConCache.delete(:vote_cache, "vote_#{vote.id}")
        ConCache.delete(:vote_cache, "index_status_#{channel_id}_open")
        ConCache.delete(:vote_cache, "index_status_#{channel_id}_closed")
        ConCache.delete(:vote_cache, "all_status_open")
        ConCache.delete(:vote_cache, "index_#{channel_id}")
        GenServer.cast(:vote_progress, {:add_vote, vote.id})
        Appsignal.increment_counter("num_votes")

        conn
        |> render("show.json", %{vote: vote})

      {:error, e} ->
        Logger.warn("VoteController.create.insert_failed=#{inspect(e)}")

        conn
        |> put_status(:bad_request)
        |> json(%{ok: false, message: "Bad request"})
    end
  end

  def set_status(conn, %{"id" => channel_id, "vote_id" => vote_id, "status" => status}) do
    vote_id = String.to_integer(vote_id)

    case Stream.change_vote_status(vote_id, status) do
      {:ok, vote} ->
        ConCache.delete(:vote_cache, "vote_#{vote.id}")
        ConCache.delete(:vote_cache, "index_status_#{channel_id}_open")
        ConCache.delete(:vote_cache, "index_status_#{channel_id}_closed")
        ConCache.delete(:vote_cache, "all_status_open")
        ConCache.delete(:vote_cache, "index_#{channel_id}")

        if status == "closed" do
          # SEND
          GenServer.cast(:vote_progress, {:remove_vote, vote.id})
        end

        conn
        |> render("show.json", %{vote: vote})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{ok: false, message: "Not found"})

      {:error, e} ->
        Logger.warn("VoteController.set_status.update_failed=#{inspect(e)}")

        conn
        |> put_status(:bad_request)
        |> json(%{ok: false, message: "Bad request"})
    end
  end

  def vote_for_ship(conn, %{"vote_id" => vote_id, "ship_id" => ship_id}) do
    vote_id = String.to_integer(vote_id)

    with %Vote{} = vote <- Repo.get(Vote, vote_id) do
      case %VotedShip{}
           |> VotedShip.changeset(%{
             "vote_id" => vote_id,
             "user_id" => conn.assigns[:user_data][:opaque_user_id],
             "ship_id" => ship_id
           })
           |> Repo.insert() do
        {:ok, _} ->
          ConCache.delete(:vote_cache, "vote_#{vote.id}")
          ConCache.delete(:vote_cache, :index_status)
          ConCache.delete(:vote_cache, :index)

          Appsignal.increment_counter("num_voted_ships")

          conn
          |> json(%{ok: true})

        {:error, e} ->
          Logger.warn("VoteController.vote_for_ship.failed=#{inspect(e)}")

          conn
          |> put_status(:bad_request)
          |> json(%{ok: false, message: "Bad request"})
      end
    else
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{ok: false, message: "Not found"})
    end
  end
end
