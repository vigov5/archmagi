defmodule ArchmagiWeb.PageController do
  use ArchmagiWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def lobby(conn, _params) do
    {player_id, player_name} =
      case Pow.Plug.current_user(conn) do
        nil -> {0, ""}
        user -> {user.id, user.email}
      end

    conn
    |> assign(:player_name, player_name)
    |> assign(:player_id, player_id)
    |> render("lobby.html")
  end

  def credit(conn, _params) do
    render(conn, "credit.html")
  end
end
