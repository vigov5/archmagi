defmodule ArchmagiWeb.DeckController do
  use ArchmagiWeb, :controller
  import Phoenix.LiveView.Controller

  alias Archmagi.Repo

  def index(conn, _params) do
    decks =
      Ecto.assoc(conn.assigns.current_user, :decks)
      |> Repo.all()

    live_render(conn, ArchmagiWeb.Live.ConstructionView,
      session: %{
        decks: decks,
        user: conn.assigns.current_user
      }
    )
  end
end
