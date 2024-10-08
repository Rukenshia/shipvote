defmodule BackendWeb.ChannelController do
  require Logger

  use BackendWeb, :controller

  alias Backend.Repo
  alias Backend.Stream
  alias Backend.Stream.Channel
  alias BackendWeb.Router.Helpers, as: Routes

  alias Backend.Twitch.Api

  action_fallback(BackendWeb.FallbackController)

  defp find_account_id(username, realm) do
    Backend.Wows.Api.find_account_id(username, realm)
  end

  def index(conn, _params) do
    channels = Stream.list_channels()
    render(conn, :index, channels: channels)
  end

  def create(conn, %{"wows_username" => username, "wows_realm" => realm} = channel_params) do
    case Stream.get_channel(channel_params |> Map.get("id")) do
      %Channel{} ->
        Logger.warning(
          "channel_controller.create.reroute_to_update channel_id=#{Map.get(channel_params, "id")}"
        )

        update(conn, %{"id" => channel_params |> Map.get("id"), "channel" => channel_params})

      _ ->
        with {:ok, account_id} <- find_account_id(username, realm),
             {:ok, %Channel{} = channel} <-
               Stream.create_channel(channel_params |> Map.put("wows_account_id", account_id)),
             {:ok, %Channel{} = channel} <- Stream.update_channel_ships(channel) do
          conn
          |> put_status(:created)
          |> put_resp_header("location", Routes.channel_path(conn, :show, channel))
          |> render(:show, channel: channel |> load_ships())
        else
          {:error, "Player not found"} ->
            conn
            |> put_status(:not_found)
            |> json(%{ok: false, message: "Player not found"})

          {:error, %Ecto.Changeset{}} ->
            # TODO: render errors
            conn
            |> put_status(:bad_request)
            |> json(%{ok: false, message: "Bad request"})

          {:error, message} ->
            Logger.error(inspect(message))

            conn
            |> put_status(:internal_server_error)
            |> json(%{ok: false, message: message})
        end
    end
  end

  def show(conn, %{"id" => id}) do
    with %Backend.Stream.Channel{} = channel <-
           Stream.get_channel(id)
           |> Repo.preload(:ships) do
      render(conn, :show, channel: channel |> load_ships(), recent_ships: Channel.most_recently_used_ships(channel))
    else
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{ok: false, message: "Not found"})
    end
  end

  def show_public_info(conn, %{"id" => id}) do
    channel =
      case ConCache.get(:channel_cache, id) do
        nil ->
          Appsignal.increment_counter("channel_public_info_missed_cache", 1, %{
            "channel_id" => id,
            "result" => "miss"
          })

          item =
            case Repo.get(Channel, id) do
              %Channel{} = c ->
                %ConCache.Item{
                  value: c |> Repo.preload(:ships),
                  ttl: :timer.seconds(30)
                }

              nil ->
                %ConCache.Item{value: :not_found, ttl: :timer.seconds(30)}
            end

          :ok = ConCache.put(:channel_cache, id, item)

          item.value

        item ->
          Appsignal.increment_counter("channel_public_info_missed_cache", 1, %{
            "channel_id" => id,
            "result" => "hit"
          })

          item
      end

    case channel do
      %Channel{} = channel ->
        conn |> render(:show_public, channel: channel)

      :not_found ->
        conn |> put_status(:not_found) |> json(%{ok: false, message: "Not found"})
    end
  end

  def update(conn, %{"id" => id, "channel" => channel_params}) do
    channel = Stream.get_channel!(id)

    Logger.info(
      "channel.update.channel=#{channel.id},wows_username=#{channel_params["wows_username"]}"
    )

    with {:ok, channel} <-
           update_account_id(
             channel,
             channel_params["wows_username"] || channel.wows_username,
             channel_params["wows_realm"] || channel.wows_realm
           ),
         {:ok, %Channel{} = channel} <-
           Stream.update_channel(channel, Map.delete(channel_params, "wows_account_id")),
         {:ok, %Channel{} = channel} <- Stream.update_channel_ships(channel) do
      ConCache.delete(:channel_cache, id)

      # notify active clients
      Backend.Twitch.Api.broadcast_message(channel.id, "channel_update", %{
        overlay_position: channel.overlay_position
      })

      render(conn, :show, channel: channel |> load_ships())
    else
      {:error, "Player not found"} ->
        conn
        |> put_status(:not_found)
        |> json(%{ok: false, message: "Player not found"})

      {:error, changeset} ->
        Logger.warning("channel.update.failed.changeset")
        Logger.warning(inspect(changeset))

        conn
        |> put_status(:bad_request)
        |> json(%{ok: false, message: "Bad request"})
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
      |> Map.put(
        :ships,
        Enum.map(channel.ships, fn s ->
          Repo.preload(s, :ship)
          |> Map.put(:enabled, s.enabled)
        end)
      )

    channel
  end

  defp update_account_id(channel, new_username, realm) do
    Logger.debug("update_account_id.stored=#{channel.wows_username},new=#{new_username}")

    if new_username == channel.wows_username do
      Logger.debug("update_account_id.no_change")
      {:ok, channel}
    else
      Logger.debug("update_account_id.find_id")

      with {:ok, account_id} <- find_account_id(new_username, realm) do
        Logger.debug("update_account_id.old_id=#{channel.wows_account_id},new_id=#{account_id}")

        channel
        |> Channel.changeset(%{"wows_account_id" => account_id, "wows_realm" => realm})
        |> Repo.update()
      else
        {:error, message} ->
          {:error, message}
      end
    end
  end
end
