defmodule BackendWeb.VoteController do
  use BackendWeb, :controller
  require Logger

  alias Backend.Repo
  alias Backend.Stream.Vote
  alias Backend.Stream.VotedShip

  import Ecto.Query, only: [from: 2]

  ## TODO
  ## * Improve caching, migrate to single cache and pick results
  ## * Changeset error handling for duplicate vote

  def index(conn, %{"id" => channel_id, "status" => status})
      when status == "open" or status == "closed" do
    votes =
      ConCache.get_or_store(:rest_vote_cache, "index_status_#{channel_id}_#{status}", fn ->
        votes =
          from(p in Backend.Stream.Vote,
            where: p.channel_id == ^channel_id and p.status == ^status
          )
          |> Repo.all()
          |> Repo.preload(:votes)

        %ConCache.Item{value: votes, ttl: :timer.seconds(2)}
      end)

    conn
    |> render("votes.json", %{votes: votes})
  end

  def index(conn, %{"id" => channel_id}) do
    votes =
      ConCache.get_or_store(:rest_vote_cache, "index_#{channel_id}", fn ->
        votes =
          from(p in Backend.Stream.Vote,
            where: p.channel_id == ^channel_id
          )
          |> Repo.all()
          |> Repo.preload(:votes)

        %ConCache.Item{value: votes, ttl: :timer.seconds(2)}
      end)

    conn
    |> render("votes.json", %{votes: votes})
  end

  def show(conn, %{"id" => channel_id, "vote_id" => vote_id}) do
    vote_id = String.to_integer(vote_id)

    vote =
      ConCache.get_or_store(:rest_vote_cache, vote_id, fn ->
        case Repo.get(Vote, vote_id) do
          %Vote{} = v -> %ConCache.Item{value: v |> Repo.preload(:votes), ttl: :timer.seconds(2)}
          nil -> %ConCache.Item{value: :not_found, ttl: :timer.seconds(2)}
        end
      end)

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
        ConCache.delete(:rest_vote_cache, vote.id)
        ConCache.delete(:rest_vote_cache, "index_status_#{channel_id}_open")
        ConCache.delete(:rest_vote_cache, "index_status_#{channel_id}_closed")
        ConCache.delete(:rest_vote_cache, "index_#{channel_id}")

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

    with %Vote{} = vote <- Repo.get(Vote, vote_id) do
      case vote
           |> Vote.status_changeset(%{"status" => status})
           |> Repo.update() do
        {:ok, vote} ->
          ConCache.delete(:rest_vote_cache, vote.id)
          ConCache.delete(:rest_vote_cache, "index_status_#{channel_id}_open")
          ConCache.delete(:rest_vote_cache, "index_status_#{channel_id}_closed")
          ConCache.delete(:rest_vote_cache, "index_#{channel_id}")

          conn
          |> render("show.json", %{vote: vote})

        {:error, e} ->
          Logger.warn("VoteController.set_status.update_failed=#{inspect(e)}")

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
          ConCache.delete(:rest_vote_cache, vote.id)
          ConCache.delete(:rest_vote_cache, :index_status)
          ConCache.delete(:rest_vote_cache, :index)

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
