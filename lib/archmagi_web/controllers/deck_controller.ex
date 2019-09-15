defmodule ArchmagiWeb.DeckController do
  use ArchmagiWeb, :controller

  alias Archmagi.Repo
  alias Archmagi.Decks
  alias Archmagi.Decks.Deck

  def index(conn, _params) do
    decks =
      Ecto.assoc(conn.assigns.current_user, :decks)
      |> Repo.all()

    render(conn, "index.html", decks: decks)
  end

  def new(conn, _params) do
    changeset = Decks.change_deck(%Deck{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"deck" => deck_params}) do
    case Decks.create_deck(conn.assigns.current_user, deck_params) do
      {:ok, deck} ->
        conn
        |> put_flash(:info, "Deck created successfully.")
        |> redirect(to: Routes.deck_path(conn, :show, deck))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    deck = Decks.get_deck!(id)
    render(conn, "show.html", deck: deck)
  end

  def edit(conn, %{"id" => id}) do
    deck = Decks.get_deck!(id)
    changeset = Decks.change_deck(deck)
    render(conn, "edit.html", deck: deck, changeset: changeset)
  end

  def update(conn, %{"id" => id, "deck" => deck_params}) do
    deck = Decks.get_deck!(id)

    case Decks.update_deck(deck, deck_params) do
      {:ok, deck} ->
        conn
        |> put_flash(:info, "Deck updated successfully.")
        |> redirect(to: Routes.deck_path(conn, :show, deck))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", deck: deck, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    deck = Decks.get_deck!(id)
    {:ok, _deck} = Decks.delete_deck(deck)

    conn
    |> put_flash(:info, "Deck deleted successfully.")
    |> redirect(to: Routes.deck_path(conn, :index))
  end
end
