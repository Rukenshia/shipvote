defmodule BackendWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :backend
  # use Appsignal.Phoenix
  require Logger

  def log_ip(conn, _) do
    conn.remote_ip
    |> Tuple.to_list()
    |> Enum.join(".")
    |> Logger.info()

    conn
  end

  socket "/live", Phoenix.LiveView.Socket

  plug(CORSPlug, origin: ["*"])

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :backend,
    gzip: false,
    only: ~w(assets fonts images videos favicon.ico favicon.png robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug(Plug.Logger)
  plug(:log_ip)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug(Plug.Session,
    store: :cookie,
    key: "_backend_key",
    signing_salt: "JZUzjavG",
    # 1 hour max age
    max_age: 60 * 60
  )

  plug(BackendWeb.Router)

  @doc """
  Callback invoked for dynamically configuring the endpoint.

  It receives the endpoint configuration and checks if
  configuration should be loaded from the system environment.
  """
  def init(_key, config) do
    if config[:load_from_system_env] do
      port = System.get_env("PORT") || raise "expected the PORT environment variable to be set"
      {:ok, Keyword.put(config, :http, [:inet6, port: port])}
    else
      {:ok, config}
    end
  end
end
