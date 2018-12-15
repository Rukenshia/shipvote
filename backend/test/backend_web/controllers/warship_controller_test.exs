defmodule BackendWeb.WarshipControllerTest do
  use BackendWeb.ConnCase

  alias Backend.Wows
  alias Backend.Wows.Warship

  @create_attrs %{
    name: "some name",
    premium: true,
    tier: 42,
    image: "image",
    nation: "usn",
    type: "AirCarrier"
  }
  @update_attrs %{
    name: "some updated name",
    premium: false,
    tier: 43,
    nation: "ijn",
    image: "updated_image",
    type: "Destroyer"
  }
  @invalid_attrs %{name: nil, premium: nil, tier: nil, nation: nil, image: nil, type: nil}

  def fixture(:warship) do
    {:ok, warship} = Wows.create_warship(@create_attrs)
    warship
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all warships", %{conn: conn} do
      conn = get(conn, warship_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create warship" do
    test "renders warship when data is valid", %{conn: conn} do
      conn = post conn, warship_path(conn, :create), warship: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, warship_path(conn, :show, id))

      assert json_response(conn, 200)["data"] == %{
               "id" => id,
               "name" => "some name",
               "premium" => true,
               "tier" => 42,
               "nation" => "usn",
               "type" => "AirCarrier",
               "image" => "image"
             }
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, warship_path(conn, :create), warship: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update warship" do
    setup [:create_warship]

    test "renders warship when data is valid", %{conn: conn, warship: %Warship{id: id} = warship} do
      conn = put conn, warship_path(conn, :update, warship), warship: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, warship_path(conn, :show, id))

      assert json_response(conn, 200)["data"] == %{
               "id" => id,
               "name" => "some updated name",
               "premium" => false,
               "tier" => 43,
               "nation" => "ijn",
               "type" => "Destroyer",
               "image" => "updated_image"
             }
    end

    test "renders errors when data is invalid", %{conn: conn, warship: warship} do
      conn = put conn, warship_path(conn, :update, warship), warship: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete warship" do
    setup [:create_warship]

    test "deletes chosen warship", %{conn: conn, warship: warship} do
      conn = delete(conn, warship_path(conn, :delete, warship))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, warship_path(conn, :show, warship))
      end
    end
  end

  defp create_warship(_) do
    warship = fixture(:warship)
    {:ok, warship: warship}
  end
end
