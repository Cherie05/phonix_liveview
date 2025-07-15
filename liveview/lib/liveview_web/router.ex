defmodule LiveviewWeb.Router do
  use LiveviewWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LiveviewWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug LiveviewWeb.Plugs.NoCache

  end

   # Simple admin pipeline—extends :browser with JSON support
  pipeline :admin do
    plug :accepts, ["html", "json"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  # … your existing scopes …

  # mount Kaffy under /admin
  scope "/" do
    pipe_through [:admin]
    use Kaffy.Routes, scope: "/admin"
  end


  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LiveviewWeb do
    pipe_through :browser


    live "/thermostat", ThermostatLive
    live "/home", HomeLive, :index
    live "/dropdown", DropdownLive, :show
    live "/navbar", NavbarLive, :show
    live "/carousel", CarouselLive, :show


    get  "/signup", PageController, :signup
    post "/signup", PageController, :create_signup

    get  "/login",  PageController, :login
    post "/login",  PageController, :create_login
    post "/logout", PageController, :logout


  end

  # Other scopes may use custom stacks.
  # scope "/api", LiveviewWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:liveview, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: LiveviewWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
