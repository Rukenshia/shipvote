defmodule Backend.Wows.BackgroundRefresh do
  use GenServer
  require Logger

  alias Backend.Repo

  import Ecto.Query, only: [from: 2]

  def start_link do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    Process.send(self(), :work, [:noconnect])
    {:ok, state}
  end

  def handle_info(:work, state) do
    if Application.get_env(:backend, Backend.Wows.BackgroundRefresh)[:disabled] == true do
      {:noreply, state}
    else
      do_work(state)
    end
  end

  def do_work(state) do
    Logger.info("BackgroundRefresh.handle_info")

    ships =
      Backend.Wows.Api.get_warships()
      |> Map.values()
      |> filter_clan_battle_ships()
      |> filter_testing_ships()
      |> Enum.map(fn data ->
        case from(s in Backend.Wows.Warship, where: s.id == ^data["ship_id"]) |> Repo.one() do
          %Backend.Wows.Warship{} = ship ->
            ship

          nil ->
            %Backend.Wows.Warship{id: data["ship_id"]}
        end
        |> Backend.Wows.Warship.changeset_from_api(data)
      end)

    Logger.debug("BackgroundRefresh.handle_info.ships_count=#{length(ships)}")

    ships =
      ships
      |> Enum.map(fn s ->
        s
        |> Repo.insert_or_update!()
      end)

    # Clean up ships that do not exist anymore
    ids = Enum.map(ships, fn s -> s.id end)

    deleted_ships =
      from(s in Backend.Wows.Warship,
        where: s.id in ^ids
      )
      |> Repo.all()

    Logger.info(
      "BackgroundRefresh: deleting #{length(deleted_ships)} ships from the database: #{
        deleted_ships |> Enum.map(fn s -> s.name end) |> Enum.join(", ")
      }"
    )

    Logger.debug("BackgroundRefresh.handle_info.ships_updated")

    # Reschedule
    schedule()
    {:noreply, state}
  end

  defp filter_clan_battle_ships(ships) do
    ships
    |> Enum.filter(fn data ->
      !(data["description"] =~ "Clan Battle" || data["name"] =~ ~r/\[.*\]/)
    end)
  end

  defp filter_testing_ships(ships) do
    ships
    |> Enum.filter(fn data ->
      !(data["name"] =~ "#2") && !(data["name"] == "Brennus")
    end)
  end

  defp schedule() do
    # Every 6 hours
    Process.send_after(self(), :work, 6 * 60 * 60 * 1000)
  end
end
