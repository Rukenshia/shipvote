defmodule BackendWeb.Router do
  use BackendWeb, :router
  require Logger

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :verify_jwt do
    plug(:check_jwt)
  end

  def check_jwt(%{params: %{"id" => channel_id}} = conn, _) do
    with ["Bearer " <> jwt] <- get_req_header(conn, "authorization"),
         %{error: nil} = decoded <-
           jwt
           |> Joken.token()
           |> Joken.with_signer(
             Joken.hs256(
               Application.get_env(:backend, BackendWeb.UserSocket)[:twitch_secret_key]
               |> Base.decode64!()
             )
           )
           |> Joken.verify() do
      claims = Joken.get_claims(decoded)

      if claims["channel_id"] != channel_id do
        Logger.error(
          "check_jwt.channel_id_check_failed.claim=#{channel_id},req=#{claims["channel_id"]}"
        )

        conn
        |> put_status(:unauthorized)
        |> json(%{ok: false, message: "unauthorized"})
        |> halt()
      else
        conn
        |> assign(:token, jwt)
        |> assign(:user_data, %{
          channel_id: claims["channel_id"],
          user_id: claims["user_id"],
          opaque_user_id: claims["opaque_user_id"],
          role: claims["role"]
        })
      end
    else
      %{error: e} ->
        Logger.error("check_jwt.attempt_unauthorized")

        conn
        |> put_status(:unauthorized)
        |> json(%{ok: false, message: "unauthorized"})
        |> halt()

      x ->
        Logger.debug(inspect(x))

        conn
        |> put_status(:unauthorized)
        |> json(%{ok: false, message: "unauthorized"})
        |> halt()
    end
  end

  scope "/", BackendWeb do
    get("/privacy-policy", NoticeController, :privacy_policy)
  end

  scope "/api", BackendWeb do
    pipe_through(:api)

    resources("/warships", WarshipController, except: [:new, :edit])

    scope "/settings" do
      pipe_through(:verify_jwt)

      resources("/channels", ChannelController, except: [:new, :edit]) do
        get("/ships", ChannelShipController, :get_channel_ships)
      end
    end
  end
end
