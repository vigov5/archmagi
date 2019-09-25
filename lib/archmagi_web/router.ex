defmodule ArchmagiWeb.Router do
  use ArchmagiWeb, :router
  use Pow.Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admin do
    plug ArchmagiWeb.EnsureRolePlug, :admin
  end

  pipeline :protected do
    plug Pow.Plug.RequireAuthenticated,
      error_handler: ArchmagiWeb.AuthErrorHandler
  end

  pipeline :not_authenticated do
    plug Pow.Plug.RequireNotAuthenticated,
      error_handler: ArchmagiWeb.AuthErrorHandler
  end

  scope "/", ArchmagiWeb do
    pipe_through [:browser, :not_authenticated]

    get "/signup", RegistrationController, :new, as: :signup
    post "/signup", RegistrationController, :create, as: :signup
    get "/login", SessionController, :new, as: :login
    post "/login", SessionController, :create, as: :login
  end

  scope "/" do
    pipe_through :browser
  end

  scope "/", ArchmagiWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/credit", PageController, :credit
  end

  scope "/", ArchmagiWeb do
    pipe_through [:browser, :protected]

    get "/lobby", PageController, :lobby
    resources "/decks", DeckController
    delete "/logout", SessionController, :delete, as: :logout
  end

  scope "/admin", ArchmagiWeb do
    pipe_through [:browser, :protected, :admin]

    resources "/cards", CardController
  end

  # Other scopes may use custom stacks.
  # scope "/api", ArchmagiWeb do
  #   pipe_through :api
  # end
end
