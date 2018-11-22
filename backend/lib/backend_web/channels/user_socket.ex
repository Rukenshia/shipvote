defmodule BackendWeb.UserSocket do
  use Phoenix.Socket

  require Logger

  ## Channels
  channel("stream:*", BackendWeb.StreamChannel)

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  def connect(%{"token" => jwt}, socket) do
    decoded =
      jwt
      |> Joken.token()
      |> Joken.with_signer(
        Joken.hs256(
          Application.get_env(:backend, BackendWeb.UserSocket)[:twitch_secret_key]
          |> Base.decode64!()
        )
      )
      |> Joken.verify()

    claims = Joken.get_claims(decoded)

    socket =
      socket
      |> assign(:token, jwt)
      |> assign(:user_data, %{
        channel_id: claims["channel_id"],
        user_id: claims["user_id"],
        opaque_user_id: claims["opaque_user_id"],
        role: claims["role"]
      })

    {:ok, socket}
  end

  def connect(_params, socket) do
    Logger.info("connect.denied.forbidden")
    {:error, %{reason: "forbidden"}}
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     BackendWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(_socket), do: nil
end
