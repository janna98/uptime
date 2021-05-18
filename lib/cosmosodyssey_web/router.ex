defmodule CosmosodysseyWeb.Router do
  use CosmosodysseyWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    #plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    #plug :put_root_layout, {CosmosodysseyWeb.LayoutView, :root}
  end

  pipeline :browser_auth do
    plug Cosmosodyssey.AuthPipeline
  end

  pipeline :ensure_auth do
    plug Guardian.Plug.EnsureAuthenticated
  end

  pipeline :api do
    plug :accepts, ["json"]
  end


  scope "/", CosmosodysseyWeb do
    pipe_through [:browser]
    resources "/sessions", SessionController, only: [:new, :create, :delete]
    resources "/users", UserController, only: [:new, :create]
  end

  scope "/", CosmosodysseyWeb do
    pipe_through [:browser, :browser_auth]
    get "/", PageController, :index
  end

  scope "/", CosmosodysseyWeb do
    pipe_through [:browser, :browser_auth, :ensure_auth]
    resources "/bookings", BookingController, only: [:new, :create, :index]
    get "/routes", RouteController, :index
    get "/search", SearchController, :search
  end

  # Other scopes may use custom stacks.
  # scope "/api", CosmosodysseyWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: CosmosodysseyWeb.Telemetry
    end
  end
end
