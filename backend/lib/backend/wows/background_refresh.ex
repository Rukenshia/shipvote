defmodule Backend.Wows.BackgroundRefresh do
  use GenServer
  require Logger

  alias Backend.Repo

  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    Process.send(self(), :work, [:noconnect])
    {:ok, state}
  end

  def handle_info(:work, state) do
    Logger.info("BackgroundRefresh.handle_info")

    # ships =
    #   Backend.Wows.Api.get_warships()
    #   |> Map.values()
    #   |> Enum.map(fn data ->
    #     case Backend.Wows.get_warship!(data["ship_id"]) do
    #       %Backend.Wows.Warship{} = ship ->
    #         ship

    #       nil ->
    #         %Backend.Wows.Warship{id: data["ship_id"]}
    #     end
    #     |> Backend.Wows.Warship.changeset_from_api(data)
    #   end)

    # Logger.debug("BackgroundRefresh.handle_info.ships_count=#{length(ships)}")

    # for ship <- ships do
    #   ship
    #   |> Repo.insert_or_update!()
    # end

    Logger.debug("BackgroundRefresh.handle_info.ships_updated")

    # Reschedule
    schedule()
    {:noreply, state}
  end

  defp schedule() do
    # Every 6 hours
    Process.send_after(self(), :work, 6 * 60 * 60 * 1000)
  end
end
