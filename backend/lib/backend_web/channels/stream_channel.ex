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

    if !is_nil(vote) do
      push(socket, "status", %{voting: true, ships: vote.ships})
    else
      push(socket, "status", %{voting: false})
    end

    {:noreply, socket}
  end

  def handle_in(
        "open_vote",
        _params,
        %{assigns: %{user_data: %{role: "broadcaster", channel_id: channel_id}}} = socket
      ) do
    vote =
      case from(v in Backend.Stream.Vote,
             where: v.status == "open" and v.channel_id == ^channel_id
           )
           |> Repo.one() do
        %Backend.Stream.Vote{} = v ->
          v

        nil ->
          %Backend.Stream.Vote{}
          |> Backend.Stream.Vote.changeset(%{channel_id: channel_id, status: "open", ships: []})
          |> Repo.insert!()
      end

    broadcast!(socket, "status", %{voting: vote.status == "open"})
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
      vote =
        vote
        |> Backend.Stream.Vote.changeset(%{status: "closed"})
        |> Repo.update!()

      broadcast!(socket, "status", %{voting: vote.status == "open"})
    end

    {:noreply, socket}
  end

  def handle_in("vote", _params, socket) do
    {:noreply, socket}
  end

  def handle_in("open_vote", _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_in("close_vote", _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end
end
