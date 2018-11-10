defmodule BackendWeb.NoticeController do
  use BackendWeb, :controller

  def privacy_policy(conn, _params) do
    render(conn, "privacy_policy.html")
  end
end
