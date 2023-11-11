defmodule Backend.Stream.ChannelShipRefresh do
  use GenServer
  require Logger

  alias Backend.Stream

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    Logger.error("ChannelShipRefresh.init")
    schedule()

    {:ok, state}
  end

  def handle_info(:reschedule, state) do
    Logger.error("ChannelShipRefresh.reschedule")

    schedule()
    {:noreply, state}
  end

  def handle_info({:work, channel}, state) do
    Logger.debug(
      "ChannelShipRefresh.handle_info.channel=#{channel.id},wows_username=#{channel.wows_username}"
    )

    do_work(channel, state)
  end

  def do_work(channel, state) do
    Logger.error("ChannelShipRefresh.do_work for channel_id=#{channel.id}")

    try do
      case Stream.update_channel_ships(channel) do
        {:ok, _} ->
          Logger.debug("ChannelShipRefresh.do_work(#{channel.id}).success")

        {:error, e} ->
          Logger.error(
            "ChannelShipRefresh: updating failed for channel #{channel.id}: #{inspect(e)}"
          )
      end
    rescue
      e ->
        Logger.error("ChannelShipRefresh failed: #{inspect(e)}")
    end

    {:noreply, state}
  end

  defp schedule() do
    # schedule all channels
    Stream.list_channels()
    |> Enum.each(&start_update/1)

    # Use global rescheduling because new channels might be available
    Process.send_after(self(), :reschedule, 24 * 60 * 60 * 1000)
    Logger.debug("ChannelShipRefresh.schedule.next=24 hours")
  end

  defp start_update(channel) do
    Process.send(self(), {:work, channel}, [:noconnect])
  end
end
