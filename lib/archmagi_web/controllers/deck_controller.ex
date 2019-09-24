defmodule ArchmagiWeb.DeckController do
  use ArchmagiWeb, :controller
  import Phoenix.LiveView.Controller

  alias Archmagi.Decks

  def index(conn, _params) do
    decks = Decks.decks_of_user(conn.assigns.current_user)

    live_render(conn, ArchmagiWeb.Live.ConstructionView,
      session: %{
        decks: decks,
        user: conn.assigns.current_user
      }
    )
  end
end
