defmodule BackendWeb.ChannelShipControllerTest do
  use BackendWeb.ConnCase

  alias Backend.Stream
  alias Backend.Stream.ChannelShip

  @create_attrs %{

  }
  @update_attrs %{

  }
  @invalid_attrs %{}

  def fixture(:channel_ship) do
    {:ok, channel_ship} = Stream.create_channel_ship(@create_attrs)
    channel_ship
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all channel_ships", %{conn: conn} do
      conn = get(conn, Routes.channel_ship_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create channel_ship" do
    test "renders channel_ship when data is valid", %{conn: conn} do
      conn = post(conn, Routes.channel_ship_path(conn, :create), channel_ship: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, Routes.channel_ship_path(conn, :show, id))

      assert %{
               "id" => id
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, Routes.channel_ship_path(conn, :create), channel_ship: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update channel_ship" do
    setup [:create_channel_ship]

    test "renders channel_ship when data is valid", %{conn: conn, channel_ship: %ChannelShip{id: id} = channel_ship} do
      conn = put(conn, Routes.channel_ship_path(conn, :update, channel_ship), channel_ship: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, Routes.channel_ship_path(conn, :show, id))

      assert %{
               "id" => id
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, channel_ship: channel_ship} do
      conn = put(conn, Routes.channel_ship_path(conn, :update, channel_ship), channel_ship: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete channel_ship" do
    setup [:create_channel_ship]

    test "deletes chosen channel_ship", %{conn: conn, channel_ship: channel_ship} do
      conn = delete(conn, Routes.channel_ship_path(conn, :delete, channel_ship))
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, Routes.channel_ship_path(conn, :show, channel_ship))
      end
    end
  end

  defp create_channel_ship(_) do
    channel_ship = fixture(:channel_ship)
    {:ok, channel_ship: channel_ship}
  end
end
