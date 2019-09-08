defmodule ArchmagiWeb.PageController do
  use ArchmagiWeb, :controller

  def index(conn, _params) do
    # TODO define plug
    {conn, player_name} =
      case get_session(conn, :player_name) do
        nil ->
          new_name = "p_#{:rand.uniform(10_000_000_000)}"
          {put_session(conn, :player_name, new_name), new_name}

        name ->
          {conn, name}
      end

    conn
    |> assign(:player_name, player_name)
    |> render("index.html")
  end
end
