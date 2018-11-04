defmodule BackendWeb.WarshipController do
  use BackendWeb, :controller

  alias Backend.Wows
  alias Backend.Wows.Warship

  action_fallback(BackendWeb.FallbackController)

  def index(conn, _params) do
    warships = Wows.list_warships()
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
