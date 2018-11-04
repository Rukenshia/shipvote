defmodule BackendWeb.StreamChannel do
  use Phoenix.Channel
  require Logger

  def join("stream:" <> broadcast_id, params, %{assigns: %{:token => jwt}} = socket) do
    {:ok, socket}
  end

  def join("stream:" <> broadcast_id, params, socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_in("get_status", _params, socket) do
    push(socket, "status", %{voting: true})
    {:noreply, socket}
  end
end
