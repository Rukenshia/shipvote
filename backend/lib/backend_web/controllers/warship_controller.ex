defmodule BackendWeb.WarshipController do
  use BackendWeb, :controller
  require Logger

  alias Backend.Repo
  alias Backend.Wows
  alias Backend.Wows.Warship
  import Ecto.Query, only: [from: 2]

  action_fallback(BackendWeb.FallbackController)

  # Returns a cached version of warships or queries the database
  # and then renews the cache.
  defp cache_warships() do
    ConCache.get_or_store(:ships_cache, :all_warships, fn ->
      Logger.info("cache_warships.all_warships.store")
      %ConCache.Item{value: Wows.list_warships(), ttl: :timer.seconds(2)}
    end)
  end

  ## Returns a cached version of a single warship or queries the db
  defp cache_warships(ids) do
    Logger.debug(inspect(ids))

    ConCache.get_or_store(:ships_cache, Enum.join(ids, ","), fn ->
      Logger.info("cache_warships.#{Enum.join(ids, ",")}.store")

      warships =
        from(s in Warship, where: s.id in ^ids)
        |> Repo.all()

      %ConCache.Item{value: warships, ttl: :timer.seconds(2)}
    end)
  end

  def index(conn, %{"ids" => ids}) do
    warships = cache_warships(ids)
    render(conn, "index.json", warships: warships)
  end

  def index(conn, _params) do
    warships = cache_warships()
    render(conn, "index.json", warships: warships)
  end

  def create(conn, %{"warship" => warship_params}) do
    with {:ok, %Warship{} = warship} <- Wows.create_warship(warship_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", warship_path(conn, :show, warship))
      |> render("show.json", warship: warship)
    end
  end

  def show(conn, %{"id" => id}) do
    warship = Wows.get_warship!(id)
    render(conn, "show.json", warship: warship)
  end

  def update(conn, %{"id" => id, "warship" => warship_params}) do
    warship = Wows.get_warship!(id)

    with {:ok, %Warship{} = warship} <- Wows.update_warship(warship, warship_params) do
      render(conn, "show.json", warship: warship)
    end
  end

  def delete(conn, %{"id" => id}) do
    warship = Wows.get_warship!(id)

    with {:ok, %Warship{}} <- Wows.delete_warship(warship) do
      send_resp(conn, :no_content, "")
    end
  end
end
