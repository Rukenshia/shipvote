defmodule BackendWeb.PageController do
  use BackendWeb, :controller

  def index(conn, _params) do
    text(conn, "tbd")
  end

  def health(conn, _params) do
    text(conn, "#{Application.spec(:backend, :vsn)}_aws")
  end
end
