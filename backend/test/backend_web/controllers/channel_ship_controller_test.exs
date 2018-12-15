defmodule BackendWeb.ChannelShipControllerTest do
  use BackendWeb.ConnCase

  alias Backend.Stream
  alias Backend.Stream.ChannelShip
  alias BackendWeb.Router.Helpers, as: Routes

  @secret_key Application.get_env(:backend, BackendWeb.UserSocket)[:twitch_secret_key]
              |> Base.decode64!()

  @create_attrs %{
    id: 1,
    channel_id: 1,
    ship_id: 1,
    enabled: true
  }

  @disable_attrs %{
    "id" => 1,
    "ship_id" => 1,
    "enabled" => false
  }
  @enable_attrs %{
    "id" => 1,
    "ship_id" => 1,
    "enabled" => true
  }

  def fixture(:channel_ship) do
    {:ok, channel} =
      Stream.create_channel(%{
        id: 1,
        wows_username: "username",
        wows_realm: "eu",
        wows_account_id: 1
      })

    {:ok, ship} =
      Backend.Wows.create_warship(%{
        name: "Stalingrad",
        tier: 10,
        type: "Battleship",
        image: "x"
      })

    attrs =
      @create_attrs
      |> Map.merge(%{ship_id: ship.id, channel_id: channel.id})

    {:ok, channel_ship} = Stream.create_channel_ship(attrs)
    channel_ship
  end

  setup %{conn: conn} do
    secret =
      %{"channel_id" => "1", "opaque_user_id" => "1", "user_id" => "1", "role" => "broadcaster"}
      |> Joken.token()
      |> Joken.with_signer(Joken.hs256(@secret_key))
      |> Joken.sign()
      |> Joken.get_compact()

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("authorization", "Bearer #{secret}")

    {:ok, conn: conn}
  end

  describe "update_channel_ship_status" do
    setup [:create_channel_ship]

    test "can disable the ship status", %{
      conn: conn,
      channel_ship: %ChannelShip{} = channel_ship
    } do
      conn =
        put(
          conn,
          Routes.channel_ship_path(
            conn,
            :update_channel_ship_status,
            channel_ship.channel_id,
            channel_ship.ship_id
          ),
          @disable_attrs
        )

      assert json_response(conn, 200) != %{}

      # TODO: check actual status
    end

    test "can enable the ship status", %{
      conn: conn,
      channel_ship: %ChannelShip{} = channel_ship
    } do
      conn =
        put(
          conn,
          Routes.channel_ship_path(
            conn,
            :update_channel_ship_status,
            channel_ship.channel_id,
            channel_ship.ship_id
          ),
          @enable_attrs
        )

      assert json_response(conn, 200) != %{}

      # TODO: check actual status
    end
  end

  defp create_channel_ship(_) do
    channel_ship = fixture(:channel_ship)
    {:ok, channel_ship: channel_ship}
  end
end
