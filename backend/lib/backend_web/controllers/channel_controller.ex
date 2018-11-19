defmodule BackendWeb.ChannelController do
  require Logger

  use BackendWeb, :controller

  alias Backend.Repo
  alias Backend.Stream
  alias Backend.Stream.Channel
  alias BackendWeb.Router.Helpers, as: Routes

  action_fallback(BackendWeb.FallbackController)

  defp find_account_id(username, realm) do
    Backend.Wows.Api.find_account_id(username, realm)
  end

  def index(conn, _params) do
    # channels = Stream.list_channels()
    # render(conn, "index.json", channels: channels)
    conn
    |> put_status(:not_implemented)
    |> json(%{ok: false})
  end

  def create(conn, %{"wows_username" => username, "wows_realm" => realm} = channel_params) do
    with {:ok, account_id} <- find_account_id(username, realm),
         {:ok, %Channel{} = channel} <-
           Stream.create_channel(channel_params |> Map.put("wows_account_id", account_id)),
         {:ok, %Channel{} = channel} <- Stream.update_channel_ships(channel) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.channel_path(conn, :show, channel))
      |> render("show.json", channel: channel |> load_ships())
    else
      {:error, "Player not found"} ->
        conn
        |> put_status(:not_found)
        |> json(%{ok: false, message: "Player not found"})

      {:error, message} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{ok: false, message: message})
    end
  end

  def show(conn, %{"id" => id}) do
    with %Backend.Stream.Channel{} = channel <-
           Stream.get_channel(id)
           |> Repo.preload(:ships) do
      render(conn, "show.json", channel: channel |> load_ships())
    else
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{ok: false, message: "Not found"})
    end
  end

  def update(conn, %{"id" => id, "channel" => channel_params}) do
    channel = Stream.get_channel!(id)

    Logger.info(
      "channel.update.channel=#{channel.id},wows_username=#{channel_params["wows_username"]}"
    )

    with {:ok, %Channel{} = channel} <-
           update_account_id(channel, channel_params["wows_username"] || channel.wows_username),
         {:ok, %Channel{} = channel} <- Stream.update_channel(channel, channel_params),
         {:ok, %Channel{} = channel} <- Stream.update_channel_ships(channel) do
      render(conn, "show.json", channel: channel |> load_ships())
    else
      {:error, "Player not found"} ->
        conn
        |> put_status(:not_found)
        |> json(%{ok: false, message: "Player not found"})

      {:error, changeset} ->
        Logger.warn("channel.update.failed.changeset")
        Logger.warn(inspect(changeset))

        conn
        |> put_status(:bad_request)
        |> json(%{ok: false})
    end
  end

  def delete(conn, %{"id" => id}) do
    channel = Stream.get_channel!(id)

    with {:ok, %Channel{}} <- Stream.delete_channel(channel) do
      send_resp(conn, :no_content, "")
    end
  end

  defp load_ships(channel) do
    channel =
      channel
      |> Repo.preload(:ships)

    channel =
      channel
      |> Map.put(:ships, Enum.map(channel.ships, fn s -> Repo.preload(s, :ship) end))

    channel
  end

  defp update_account_id(channel, new_username) do
    if new_username == channel.wows_username do
      {:ok, channel}
    else
      with {:ok, account_id} <- find_account_id(new_username, channel.wows_realm) do
        channel
        |> Channel.changeset(%{wows_account_id: account_id})
        |> Repo.update()
      else
        {:error, message} ->
          {:error, message}
      end
    end
  end
end
