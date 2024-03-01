defmodule Backend.Twitch.VoteProgress do
  use GenServer
  require Logger

  alias Backend.Stream
  alias Backend.Stream.Vote
  alias Backend.Twitch

  @enabled Application.compile_env(:backend, Backend.VoteProgress)[:enabled]

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: :vote_progress)
  end

  def init(state) do
    if @enabled do
      Logger.info("Twitch.VoteProgress: init")
      GenServer.cast(self(), :init)
      Process.send(self(), :work, [:noconnect])
    else
      Logger.info("Twitch.VoteProgress: no-op, not enabled")
    end

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
    Logger.warning("Twitch.VoteProgress: Adding vote #{vote_id}")

    publish_vote_status(vote_id)

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
    Logger.warning("Twitch.VoteProgress: Removing vote #{vote_id}")

    publish_vote_status(vote_id)

    ConCache.update(:vote_progress_cache, "open_votes", fn value ->
      case value do
        nil ->
          {:ok, []}

        v ->
          {:ok, Enum.filter(v, fn vid -> vid != vote_id end)}
      end
    end)

    {:noreply, state}
  end

  def do_work(state) do
    Logger.info("Twitch.VoteProgress.handle_info")

    ConCache.get_or_store(:vote_progress_cache, "open_votes", fn ->
      []
    end)
    |> Enum.map(fn vote_id ->
      # FIXME: publish vote progress after we closed votes we no longer want to publish
      publish_vote_progress(vote_id)

      vote_id
    end)
    |> Enum.filter(fn vote_id ->
      with vote = %Vote{} <- Stream.get_cached_vote(vote_id) do
        vote.status == "open" && vote.scheduled_end != nil &&
          DateTime.compare(vote.scheduled_end, DateTime.utc_now()) == :lt
      else
        _ ->
          false
      end
    end)
    |> Enum.each(fn vote_id ->
      Logger.warning("Twitch.VoteProgress: closing vote #{vote_id} because it expired")
      Backend.Stream.change_vote_status(vote_id, "closed")
      GenServer.cast(self(), {:remove_vote, vote_id})
    end)

    Logger.info("Twitch.VoteProgress.handle_info.done")

    # Reschedule
    schedule()
    {:noreply, state}
  end

  defp publish_vote_status(vote_id) do
    with vote = %Vote{} <- Stream.get_cached_vote(vote_id) do
      case Twitch.Api.broadcast_message(vote.channel_id, "vote_status", %{
             id: vote.id,
             source: "backend",
             status: vote.status
           }) do
        {:error, e} ->
          Logger.warning(
            "Twitch.VoteProgress.publish_vote_status: failed for vote_id=#{vote_id}: #{inspect(e)}"
          )

        _ ->
          Logger.info("Twitch.VoteProgress.publish_vote_status: sent for vote_id=#{vote_id}")
      end
    else
      _ ->
        Logger.warning(
          "Twitch.VoteProgress.publish_vote_status: unknown or unregistered vote #{vote_id}"
        )
    end
  end

  defp publish_vote_progress(vote_id) do
    with vote = %Vote{status: "open"} <- Stream.get_cached_vote(vote_id) do
      Logger.info("Twitch.VoteProgress.publish_vote_progress: publishing #{vote_id}")

      case Twitch.Api.broadcast_message(vote.channel_id, "vote_progress", %{
             id: vote.id,
             source: "backend",
             voted_ships:
               Enum.map(vote.votes, fn v -> v.ship_id end)
               |> Enum.reduce(%{}, fn x, acc ->
                 Map.update(acc, x, 1, &(&1 + 1))
               end)
           }) do
        {:error, e} ->
          Logger.warning(
            "Twitch.VoteProgress.publish_vote_progress: failed for vote_id=#{vote_id}: #{inspect(e)}"
          )

        _ ->
          nil
      end
    else
      %Vote{status: "closed"} ->
        Logger.warning(
          "Twitch.VoteProgress.publish_vote_progress: removing closed vote #{vote_id}"
        )

        GenServer.cast(self(), {:remove_vote, vote_id})

      _ ->
        Logger.warning(
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
