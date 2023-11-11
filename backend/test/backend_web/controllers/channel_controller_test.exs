defmodule BackendWeb.ChannelControllerTest do
  require Logger
  use BackendWeb.ConnCase

  alias Backend.Stream
  alias Backend.Stream.Channel
  alias BackendWeb.Router.Helpers, as: Routes

  import Mock

  @create_attrs %{
    id: "1",
    wows_username: "username",
    wows_realm: "eu",
    wows_account_id: "4711"
  }
  @update_attrs %{
    id: "1",
    wows_username: "updated username",
    wows_realm: "na",
    wows_account_id: "4712"
  }
  @invalid_attrs %{id: "1", wows_username: nil, wows_realm: nil, wows_account_id: nil}

  @secret_key Application.compile_env(:backend, Backend.Twitch.Api)[:twitch_secret_key]
              |> Base.decode64!()

  def fixture(:channel) do
    {:ok, channel} = Stream.create_channel(@create_attrs)
    channel
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

  describe "index" do
    test "lists all channels", %{conn: conn} do
      conn = get(conn, Routes.channel_path(conn, :index))
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create channel" do
    test "renders channel when data is valid", %{conn: conn} do
      with_mocks([
        {Backend.Stream, [:passthrough], [update_channel_ships: fn c -> {:ok, c} end]},
        {Backend.Wows.Api, [], [find_account_id: fn _a, _b -> {:ok, "4711"} end]}
      ]) do
        conn = post(conn, Routes.channel_path(conn, :create), @create_attrs)
        assert %{"id" => id} = json_response(conn, 201)["data"]

        conn = get(conn, Routes.channel_path(conn, :show, id))

        assert %{
                 "id" => 1,
                 "wows_username" => "username",
                 "wows_realm" => "eu",
                 "wows_account_id" => 4711,
                 "ships" => []
               } == json_response(conn, 200)["data"]
      end
    end

    test "renders returns a 400 when the data is invalid", %{conn: conn} do
      with_mocks([
        {Backend.Stream, [:passthrough], [update_channel_ships: fn c -> {:ok, c} end]},
        {Backend.Wows.Api, [], [find_account_id: fn _a, _b -> {:ok, "4711"} end]}
      ]) do
        conn = post(conn, Routes.channel_path(conn, :create), @invalid_attrs)
        assert json_response(conn, 400) == %{"ok" => false, "message" => "Bad request"}
      end
    end
  end

  describe "update channel" do
    setup [:create_channel]

    test "renders channel when data is valid", %{conn: conn, channel: %Channel{id: id} = channel} do
      with_mocks([
        {Backend.Stream, [:passthrough], [update_channel_ships: fn c -> {:ok, c} end]},
        {Backend.Wows.Api, [], [find_account_id: fn _a, _b -> {:ok, "4712"} end]}
      ]) do
        conn = put(conn, Routes.channel_path(conn, :update, channel), channel: @update_attrs)
        assert %{"id" => ^id} = json_response(conn, 200)["data"]

        conn = get(conn, Routes.channel_path(conn, :show, id))

        assert %{
                 "id" => 1,
                 "ships" => [],
                 "wows_username" => "updated username",
                 "wows_realm" => "na",
                 "wows_account_id" => 4712
               } == json_response(conn, 200)["data"]
      end
    end

    test "renders 400 when data is invalid", %{conn: conn, channel: channel} do
      conn = put(conn, Routes.channel_path(conn, :update, channel), channel: @invalid_attrs)
      assert json_response(conn, 400) == %{"ok" => false, "message" => "Bad request"}
    end
  end

  describe "delete channel" do
    setup [:create_channel]

    test "deletes chosen channel", %{conn: conn, channel: channel} do
      conn = delete(conn, Routes.channel_path(conn, :delete, channel))
      assert response(conn, 204)

      conn = get(conn, Routes.channel_path(conn, :show, channel))
      assert json_response(conn, 404) == %{"message" => "Not found", "ok" => false}
    end
  end

  defp create_channel(_) do
    channel = fixture(:channel)
    {:ok, channel: channel}
  end
end
