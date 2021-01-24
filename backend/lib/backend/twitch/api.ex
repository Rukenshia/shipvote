defmodule Backend.Twitch.Api do
  require Logger

  @client_id Application.get_env(:backend, BackendWeb.UserSocket)[:twitch_client_id]

  @secret_key Application.get_env(:backend, BackendWeb.UserSocket)[:twitch_secret_key]
              |> Base.decode64!()

  @doc """
  Generates a valid JWT to use for authorization in the twitch api
  """
  def generate_extension_token(channel_id) do
    token =
      %{
        channel_id: "#{channel_id}",
        user_id: "#{channel_id}",
        role: "external",
        pubsub_perms: %{
          send: ["*"]
        }
      }
      |> Joken.token()
      |> Joken.with_exp(DateTime.utc_now() |> DateTime.add(60, :second) |> DateTime.to_unix())
      |> Joken.with_signer(Joken.hs256(@secret_key))
      |> Joken.sign()
      |> Joken.get_compact()

    Logger.debug(token)
    token
  end

  def headers(channel_id) do
    [
      {"Content-Type", "application/json"},
      {"Client-Id", @client_id},
      {"Authorization", "Bearer #{generate_extension_token(channel_id)}"}
    ]
  end

  def broadcast_message(channel_id, message_type, message) do
    response =
      HTTPoison.post!(
        "https://api.twitch.tv/extensions/message/#{channel_id}",
        Jason.encode!(%{
          content_type: "application/json",
          targets: ["broadcast"],
          message:
            Jason.encode!(%{
              type: message_type,
              timestamp: DateTime.utc_now(),
              data: message
            })
            |> Base.encode64()
        }),
        headers(channel_id)
      )

    case response.status_code do
      204 ->
        {:ok, ""}

      _ ->
        {:error, response}
    end
  end
end
