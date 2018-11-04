defmodule BackendWeb.Router do
  use BackendWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/api", BackendWeb do
    pipe_through(:api)

    resources("/warships", WarshipController, except: [:new, :edit])
  end
end
