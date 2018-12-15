defmodule Backend.Auth.Twitch do
  require Logger
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  @secret_key Application.get_env(:backend, BackendWeb.UserSocket)[:twitch_secret_key]
              |> Base.decode64!()

  def init(options), do: options

  def call(conn, opts) do
    check_jwt(conn, opts)
  end

  def check_jwt(%{params: %{"id" => channel_id}} = conn, _) do
    with ["Bearer " <> jwt] <- get_req_header(conn, "authorization"),
         %{error: nil} = decoded <-
           jwt
           |> Joken.token()
           |> Joken.with_signer(Joken.hs256(@secret_key))
           |> Joken.verify() do
      claims = Joken.get_claims(decoded)

      if claims["channel_id"] != channel_id do
        Logger.error(
          "check_jwt.channel_id_check_failed.claim=#{inspect(channel_id)},req=#{
            inspect(claims["channel_id"])
          }"
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
        Logger.error(inspect(e))
        Logger.error("check_jwt.attempt_unauthorized")

        conn
        |> put_status(:unauthorized)
        |> json(%{ok: false, message: "unauthorized"})
        |> halt()

      x ->
        Logger.error(inspect(x))

        conn
        |> put_status(:unauthorized)
        |> json(%{ok: false, message: "unauthorized"})
        |> halt()
    end
  end

  def check_jwt(conn, _) do
    Logger.debug(inspect(conn.params))

    conn
    |> put_status(:unauthorized)
    |> json(%{ok: false, message: "unauthorized"})
    |> halt()
  end
end
