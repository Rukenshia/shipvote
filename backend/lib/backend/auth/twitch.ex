defmodule Backend.Auth.Twitch do
  require Logger
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  @secret_key Application.compile_env(:backend, Backend.Twitch.Api)[:twitch_secret_key]
              |> Base.decode64!()

  def init(options), do: options

  def call(conn, opts) do
    conn |> authorize(opts)
  end

  def authorize(conn, opts) do
    conn = conn |> fetch_session()

    # Check if we have an existing session, otherwise go and check JWT again
    with %{} = user_data <- get_session(conn, :user_data) do
      conn
      |> assign(:user_data, user_data)
    else
      nil ->
        Backend.Auth.Twitch.check_jwt(conn, opts)

      v ->
        Logger.error("Auth.Twitch invalid :user_data match #{inspect(v)}")
        conn
    end
  end

  # For testing
  def check_jwt(%{params: %{"id" => "1"}} = conn, _) do
    user_data = %{
      channel_id: "1",
      user_id: "1",
      opaque_user_id: "opaque_test_user_id",
      role: "broadcaster"
    }

    Logger.warning("Using testing endpoint")

    conn
    |> put_session(:user_data, user_data)
    |> assign(:user_data, user_data)
  end

  def check_jwt(%{params: %{"id" => "1234"}} = conn, _) do
    user_data = %{
      channel_id: "1234",
      user_id: "2",
      opaque_user_id: "opaque_test_user_id",
      role: "broadcaster"
    }

    Logger.warning("Using testing endpoint")

    conn
    |> put_session(:user_data, user_data)
    |> assign(:user_data, user_data)
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
          "check_jwt.channel_id_check_failed.claim=#{inspect(channel_id)},req=#{inspect(claims["channel_id"])}"
        )

        conn
        |> put_status(:unauthorized)
        |> json(%{ok: false, message: "unauthorized"})
        |> halt()
      else
        user_data = %{
          channel_id: claims["channel_id"],
          user_id: claims["user_id"],
          opaque_user_id: claims["opaque_user_id"],
          role: claims["role"]
        }

        conn
        |> put_session(:user_data, user_data)
        |> assign(:user_data, user_data)
      end
    else
      %{error: e} ->
        Logger.error(inspect(e))
        Logger.error("check_jwt.attempt_unauthorized")

        conn
        |> put_status(:unauthorized)
        |> json(%{ok: false, message: "unauthorized"})
        |> halt()

      [] ->
        Logger.warning("check_jwt.no_authorization_header")

        conn
        |> put_status(:unauthorized)
        |> json(%{ok: false, message: "unauthorized"})
        |> halt()

      x ->
        Logger.warning(inspect(x))

        conn
        |> put_status(:unauthorized)
        |> json(%{ok: false, message: "unauthorized"})
        |> halt()
    end
  end

  def check_jwt(conn, _) do
    Logger.warning("check_jwt.no_id_param=#{inspect(conn.params)}")

    conn
    |> put_status(:unauthorized)
    |> json(%{ok: false, message: "unauthorized"})
    |> halt()
  end

  def require_broadcaster(conn, _) do
    case is_broadcaster?(conn) do
      true ->
        conn

      false ->
        conn
        |> put_status(:unauthorized)
        |> json(%{ok: false, message: "unauthorized"})
        |> halt()
    end
  end

  defp is_broadcaster?(%{assigns: %{user_data: %{role: "broadcaster"}}}) do
    true
  end

  defp is_broadcaster?(_) do
    false
  end
end
