defmodule BackendWeb.StreamChannel do
  use Phoenix.Channel
  require Logger

  alias Backend.Repo
  import Ecto.Query, only: [from: 2]

  def join("stream:" <> _broadcast_id, _params, %{assigns: %{:token => jwt}} = socket) do
    {:ok, socket}
  end

  def join("stream:" <> _broadcast_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_in(
        "get_status",
        _params,
        %{assigns: %{user_data: %{channel_id: channel_id}}} = socket
      ) do
    vote =
      from(v in Backend.Stream.Vote,
        where: v.status == "open" and v.channel_id == ^channel_id
      )
      |> Repo.one()
      |> Repo.preload(:votes)

    if !is_nil(vote) do
      # count ship votes
      votes =
        vote.votes
        |> Enum.reduce(%{}, fn v, acc ->
          if Map.has_key?(acc, v.ship_id) do
            acc
            |> Map.get_and_update!(v.ship_id, fn v -> {v, v + 1} end)
            |> elem(1)
          else
            acc
            |> Map.put(v.ship_id, 1)
          end
        end)

      push(socket, "status", %{
        voting: true,
        ships: vote.ships,
        votes: votes
      })
    else
      push(socket, "status", %{voting: false})
    end

    {:noreply, socket}
  end

  def handle_in(
        "open_vote",
        %{"ships" => ships},
        %{assigns: %{user_data: %{role: "broadcaster", channel_id: channel_id}}} = socket
      ) do
    vote =
      case from(v in Backend.Stream.Vote,
             where: v.status == "open" and v.channel_id == ^channel_id
           )
           |> Repo.one() do
        %Backend.Stream.Vote{} = v ->
          Logger.info("vote.opened.channel=#{v.channel_id}")
          v

        nil ->
          %Backend.Stream.Vote{}
          |> Backend.Stream.Vote.changeset(%{channel_id: channel_id, status: "open", ships: ships})
          |> Repo.insert!()
      end

    broadcast!(socket, "status", %{
      voting: true,
      ships: vote.ships,
      votes: %{}
    })

    {:noreply, socket}
  end

  def handle_in(
        "close_vote",
        _params,
        %{assigns: %{user_data: %{role: "broadcaster", channel_id: channel_id}}} = socket
      ) do
    vote =
      from(v in Backend.Stream.Vote,
        where: v.status == "open" and v.channel_id == ^channel_id
      )
      |> Repo.one()

    if !is_nil(vote) do
      Logger.info("vote.closed.channel=#{vote.channel_id}")

      vote =
        vote
        |> Backend.Stream.Vote.changeset(%{status: "closed"})
        |> Repo.update!()

      broadcast!(socket, "status", %{voting: vote.status == "open"})
    end

    {:noreply, socket}
  end

  def handle_in(
        "vote",
        %{"ship_id" => ship_id},
        %{assigns: %{user_data: %{opaque_user_id: user_id, channel_id: channel_id}}} = socket
      ) do
    vote = Backend.Stream.get_open_vote_by_channel(channel_id)

    if !is_nil(vote) do
      user_vote =
        from(v in Backend.Stream.VotedShip,
          where: v.user_id == ^user_id and v.vote_id == ^vote.id
        )
        |> Repo.one()

      if is_nil(user_vote) do
        Logger.info(
          "vote.user_vote.channel=#{vote.channel_id},user_id=#{user_id},ship_id=#{ship_id}"
        )

        %Backend.Stream.VotedShip{}
        |> Backend.Stream.VotedShip.changeset(%{
          vote_id: vote.id,
          user_id: user_id,
          ship_id: ship_id
        })
        |> Repo.insert!()

        broadcast!(socket, "new_vote", %{ship_id: ship_id})
      else
        Logger.info(
          "vote.user_vote.duplicate.channel=#{vote.channel_id},user_id=#{user_id},ship_id=#{
            ship_id
          }"
        )
      end
    end

    {:noreply, socket}
  end

  def handle_in("open_vote", _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_in("close_vote", _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end
end
