defmodule Backend.Stream.ChannelShipRefresh do
  use GenServer
  require Logger

  alias Backend.Stream

  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    schedule()

    {:ok, state}
  end

  def handle_info(:reschedule, state) do
    {:noreply, state}
  end

  def handle_info({:work, channel}, state) do
    Logger.debug(
      "ChannelShipRefresh.handle_info.channel=#{channel.id},wows_username=#{channel.wows_username}"
    )

    if Application.get_env(:backend, Backend.Stream.ChannelShipRefresh)[:disabled] == true do
      {:noreply, state}
    else
      do_work(channel, state)
    end
  end

  def do_work(channel, state) do
    case Stream.update_channel_ships(channel) do
      {:ok, _} ->
        Logger.debug("ChannelShipRefresh.do_work(#{channel.id}).success")

      {:error, e} ->
        Logger.error(
          "ChannelShipRefresh: updating failed for channel #{channel.id}: #{inspect(e)}"
        )
    end

    {:noreply, state}
  end

  @doc """
  Schedule all available channels.
  """
  defp schedule() do
    # schedule all channels
    Stream.list_channels()
    |> Enum.each(&schedule/1)
  end

  @doc """
  Schedule to update a channels ships in 24 hours.
  """
  defp schedule(channel) do
    Process.send_after(self(), {:work, channel}, 24 * 60 * 60 * 1000)

    # Use global rescheduling because new channels might be available
    Process.send_after(self(), :reschedule, 24 * 60 * 60 * 1000)
  end
end
