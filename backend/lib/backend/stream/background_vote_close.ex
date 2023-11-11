defmodule Backend.Stream.BackgroundVoteClose do
  use GenServer
  require Logger

  alias Backend.Stream

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    Process.send(self(), :work, [:noconnect])
    {:ok, state}
  end

  def handle_info(:work, state) do
    do_work(state)
  end

  def do_work(state) do
    Logger.info("BackgroundVoteClose.handle_info")

    # Check votes older than 3 days
    date = NaiveDateTime.utc_now()
    three_days_ago = NaiveDateTime.add(date, -3 * 24 * 3600, :second)

    old_open_votes =
      Stream.get_open_votes()
      |> Enum.filter(fn vote ->
        NaiveDateTime.compare(vote.inserted_at, three_days_ago) == :lt
      end)

    Logger.debug("Found #{old_open_votes |> length} old open votes. Closing them")

    old_open_votes
    |> Enum.each(fn vote ->
      case Stream.change_vote_status(vote.id, "closed") do
        {:error, e} ->
          Logger.warning("Could not close old vote #{vote.id}: #{e}")

        _ ->
          nil
      end
    end)

    Logger.debug("BackgroundVoteClose.handle_info.done")

    # Reschedule
    schedule()
    {:noreply, state}
  end

  defp schedule() do
    # Every six hours
    Process.send_after(self(), :work, 6 * 60 * 60 * 1000)
  end
end
