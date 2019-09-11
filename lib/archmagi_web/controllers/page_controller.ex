defmodule ArchmagiWeb.PageController do
  use ArchmagiWeb, :controller

  def index(conn, _params) do
    player_name =
      case Pow.Plug.current_user(conn) do
        nil -> ""
        user -> user.email
      end

    conn
    |> assign(:player_name, player_name)
    |> render("index.html")
  end
end
