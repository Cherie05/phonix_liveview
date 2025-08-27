defmodule LiveviewWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :liveview

  @session_options [
    store: :cookie,
    key: "_liveview_key",
    signing_salt: "LBk182W1",
    same_site: "Lax"
  ]

  # Kaffy static (optional; remove if unused)
  plug Plug.Static,
    at: "/kaffy",
    from: :kaffy,
    gzip: false,
    only: ~w(assets)

  # LiveView socket
  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  # Digested assets from priv/static
  plug Plug.Static,
    at: "/",
    from: :liveview,
    gzip: false,
    only: LiveviewWeb.static_paths()

  # Serve runtime uploads from /app/uploads (container CWD)
  plug Plug.Static,
    at: "/uploads",
    from: Path.expand("./uploads"),
    gzip: false

  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :liveview
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug LiveviewWeb.Router
end
