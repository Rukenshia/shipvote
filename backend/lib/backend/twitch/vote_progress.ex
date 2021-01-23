defmodule Backend.Twitch.VoteProgress do
  use GenServer
  require Logger

  alias Backend.Stream
  alias Backend.Stream.Vote
  alias Backend.Twitch

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: :vote_progress)
  end

  def init(state) do
    Logger.info("Twitch.VoteProgress: init")
    GenServer.cast(self(), :init)
    Process.send(self(), :work, [:noconnect])
    {:ok, state}
  end

  def handle_info(:work, state) do
    do_work(state)
  end

  def handle_cast(:init, state) do
    Logger.info("Twitch.VoteProgress: handle init, loading all open votes")

    Stream.get_open_votes()
    |> Enum.each(&GenServer.cast(self(), {:add_vote, &1.id}))

    {:noreply, state}
  end

  def handle_cast({:add_vote, vote_id}, state) do
    Logger.info("Twitch.VoteProgress: Adding vote #{vote_id}")

    ConCache.update(:vote_progress_cache, "open_votes", fn value ->
      case value do
        nil ->
          {:ok, [vote_id]}

        v ->
          {:ok, v ++ [vote_id]}
      end
    end)

    {:noreply, state}
  end

  def handle_cast({:remove_vote, vote_id}, state) do
    Logger.info("Twitch.VoteProgress: Removing vote #{vote_id}")

    ConCache.update(:vote_progress_cache, "open_votes", fn value ->
      case value do
        nil ->
          {:ok, []}

        v ->
          {:ok, Enum.filter(v, fn vote -> vote.id != vote_id end)}
      end
    end)

    {:noreply, state}
  end

  def do_work(state) do
    Logger.info("Twitch.VoteProgress.handle_info")

    ConCache.get_or_store(:vote_progress_cache, "open_votes", fn ->
      []
    end)
    |> Enum.each(&publish_vote_progress/1)

    Logger.info("Twitch.VoteProgress.handle_info.done")

    # Reschedule
    schedule()
    {:noreply, state}
  end

  defp publish_vote_progress(vote_id) do
    with vote = %Vote{channel_id: 27_995_184} <- Stream.get_cached_vote(vote_id) do
      Logger.info("Twitch.VoteProgress.publish_vote_progress: publishing #{vote_id}")

      case Twitch.Api.broadcast_message(vote.channel_id, "vote_progress", %{
             id: vote.id,
             voted_ships:
               Enum.map(vote.votes, fn v -> v.ship_id end)
               |> Enum.reduce(%{}, fn x, acc ->
                 Map.update(acc, x, 1, &(&1 + 1))
               end)
           }) do
        {:error, e} ->
          Logger.warn(
            "Twitch.VoteProgress.publish_vote_progress: failed for vote_id=#{vote_id}: #{
              inspect(e)
            }"
          )

        _ ->
          nil
      end
    else
      _ ->
        Logger.warn(
          "Twitch.VoteProgress.publish_vote_progress: unknown or unregistered vote #{vote_id}"
        )
    end
  end

  defp schedule() do
    # Every 5 seconds
    # TODO: how to schedule per open vote?
    Process.send_after(self(), :work, 5 * 1000)
  end
end
