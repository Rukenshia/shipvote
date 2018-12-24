defmodule Backend.Auth.TwitchTest do
  use BackendWeb.ConnCase

  alias Backend.Auth.Twitch

  @secret_key Application.get_env(:backend, BackendWeb.UserSocket)[:twitch_secret_key]
              |> Base.decode64!()

  describe "check_jwt without params" do
    setup %{conn: conn} do
      conn = fetch_query_params(conn)

      %{conn: conn}
    end

    test "returns unauthorized when there is no id parameter", %{conn: conn} do
      conn = Twitch.check_jwt(conn, %{})

      assert json_response(conn, 401) == %{"ok" => false, "message" => "unauthorized"}
    end
  end

  describe "check_jwt with params" do
    setup %{conn: conn} do
      conn = %{conn | params: %{"id" => "1234"}}

      %{conn: conn}
    end

    test "returns unauthorized on missing Authorization header", %{conn: conn} do
      conn = Twitch.check_jwt(conn, %{})

      assert json_response(conn, 401) == %{"ok" => false, "message" => "unauthorized"}
    end

    test "returns unauthorized on a malformed Authorization header", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Password xxx")
        |> Twitch.check_jwt(%{})

      assert json_response(conn, 401) == %{"ok" => false, "message" => "unauthorized"}
    end

    test "returns unauthorized on a malformed jwt", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer xyz")
        |> Twitch.check_jwt(%{})

      assert json_response(conn, 401) == %{"ok" => false, "message" => "unauthorized"}
    end

    test "returns unauthorized on empty claims", %{conn: conn} do
      token =
        %{}
        |> Joken.token()
        |> Joken.with_signer(Joken.hs256(@secret_key))
        |> Joken.sign()
        |> Joken.get_compact()

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> Twitch.check_jwt(%{})

      assert json_response(conn, 401) == %{"ok" => false, "message" => "unauthorized"}
    end

    test "returns unauthorized on wrong id claim", %{conn: conn} do
      token =
        %{
          "channel_id" => "1",
          "opaque_user_id" => "1",
          "user_id" => "1",
          "role" => "broadcaster"
        }
        |> Joken.token()
        |> Joken.with_signer(Joken.hs256(@secret_key))
        |> Joken.sign()
        |> Joken.get_compact()

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> Twitch.check_jwt(%{})

      assert json_response(conn, 401) == %{"ok" => false, "message" => "unauthorized"}
    end

    test "passes the request with a valid jwt", %{conn: conn} do
      token =
        %{
          "channel_id" => "1234",
          "opaque_user_id" => "opaque_id",
          "user_id" => "1234",
          "role" => "broadcaster"
        }
        |> Joken.token()
        |> Joken.with_signer(Joken.hs256(@secret_key))
        |> Joken.sign()
        |> Joken.get_compact()

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> Twitch.check_jwt(%{})

      assert %Plug.Conn{state: :unset} = conn
    end

    test "sets the user_data on conn", %{conn: conn} do
      token =
        %{
          "channel_id" => "1234",
          "opaque_user_id" => "opaque_id",
          "user_id" => "1234",
          "role" => "broadcaster"
        }
        |> Joken.token()
        |> Joken.with_signer(Joken.hs256(@secret_key))
        |> Joken.sign()
        |> Joken.get_compact()

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> Twitch.check_jwt(%{})

      assert conn.assigns[:user_data] == %{
               channel_id: "1234",
               opaque_user_id: "opaque_id",
               user_id: "1234",
               role: "broadcaster"
             }
    end

    test "sets the token on conn", %{conn: conn} do
      token =
        %{
          "channel_id" => "1234",
          "opaque_user_id" => "opaque_id",
          "user_id" => "1234",
          "role" => "broadcaster"
        }
        |> Joken.token()
        |> Joken.with_signer(Joken.hs256(@secret_key))
        |> Joken.sign()
        |> Joken.get_compact()

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> Twitch.check_jwt(%{})

      assert conn.assigns[:token] == token
    end
  end

  describe "require_broadcaster" do
    setup %{conn: conn} do
      conn = %{conn | params: %{"id" => "1234"}}

      %{conn: conn}
    end

    test "halts the request with unauthorized if no user data is set", %{conn: conn} do
      assert Twitch.require_broadcaster(conn, %{}) |> json_response(401) == %{
               "ok" => false,
               "message" => "unauthorized"
             }
    end

    test "halts the request with unauthorized if the wrong role", %{conn: conn} do
      token =
        %{
          "channel_id" => "1234",
          "opaque_user_id" => "opaque_id",
          "user_id" => "1234",
          "role" => "viewer"
        }
        |> Joken.token()
        |> Joken.with_signer(Joken.hs256(@secret_key))
        |> Joken.sign()
        |> Joken.get_compact()

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> Twitch.check_jwt(%{})
        |> Twitch.require_broadcaster(%{})

      assert json_response(conn, 401) == %{"ok" => false, "message" => "unauthorized"}
    end

    test "passes the request when the role is set to broadcaster", %{conn: conn} do
      token =
        %{
          "channel_id" => "1234",
          "opaque_user_id" => "opaque_id",
          "user_id" => "1234",
          "role" => "broadcaster"
        }
        |> Joken.token()
        |> Joken.with_signer(Joken.hs256(@secret_key))
        |> Joken.sign()
        |> Joken.get_compact()

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> Twitch.check_jwt(%{})
        |> Twitch.require_broadcaster(%{})

      assert %Plug.Conn{state: :unset} = conn
    end
  end
end
