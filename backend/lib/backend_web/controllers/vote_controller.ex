defmodule BackendWeb.VoteController do
  use BackendWeb, :controller
  require Logger

  alias Backend.Repo
  alias Backend.Stream.Vote

  import Ecto.Query, only: [from: 2]

  def index(conn, %{id: channel_id, status: status}) do
  end

  def index(conn, %{"id" => channel_id}) do
    # TODO: cache
    votes =
      from(p in Backend.Stream.Vote, where: p.channel_id == ^channel_id)
      |> Repo.all()

    conn
    |> render("votes.json", %{votes: votes})
  end

  def show(conn, %{"id" => channel_id, "vote_id" => vote_id}) do
    # TODO: cache
    vote_id = String.to_integer(vote_id)

    case Repo.get(Vote, vote_id) do
      v -> conn |> render("show.json", %{vote: v})
      nil -> conn |> put_status(:not_found) |> json(%{ok: false, message: "Not found"})
    end
  end

  def create(conn, %{"id" => channel_id, "vote" => attrs}) do
    attrs = attrs |> Map.merge(%{"channel_id" => channel_id})

    case %Vote{}
         |> Vote.changeset(attrs)
         |> Repo.insert() do
      {:ok, vote} ->
        conn
        |> render("show.json", %{vote: vote})

      {:error, e} ->
        Logger.warn("VoteController.create.insert_failed=#{inspect(e)}")

        conn
        |> put_status(:bad_request)
        |> json(%{ok: false, message: "Bad request"})
    end
  end

  def set_status(conn, %{"vote_id" => vote_id, "status" => status}) do
    vote_id = String.to_integer(vote_id)

    with %Vote{} = vote <- Repo.get(Vote, vote_id) do
      case vote
           |> Vote.status_changeset(%{"status" => status})
           |> Repo.update() do
        {:ok, vote} ->
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
    # TODO: disable duplicates
    # TODO: clear cache
    vote_id = String.to_integer(vote_id)

    with %Vote{} = vote <- Repo.get(Vote, vote_id) do
      case %VotedShip{}
           |> VotedShip.changeset(%{
             "vote_id" => vote_id,
             "user_id" => conn.assigns[:user_data][:user_id],
             "ship_id" => ship_id
           })
           |> Repo.insert() do
        {:ok, _} ->
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
