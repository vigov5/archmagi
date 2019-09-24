defmodule ArchmagiWeb.Live.ConstructionView do
  use Phoenix.LiveView

  alias Archmagi.Decks

  require Logger

  def render(assigns) do
    ArchmagiWeb.DeckView.render("construction.html", assigns)
  end

  def mount(%{decks: decks, user: user}, socket) do
    if connected?(socket) do
      Logger.debug("Liveview construction connected!")
    end

    selected_deck = hd(decks)
    {info, cards} = prepare_deck(selected_deck)

    socket =
      socket
      |> assign(
        decks: decks,
        selected_deck: selected_deck,
        cards: cards,
        info: info,
        user: user
      )

    {:ok, socket}
  end

  def handle_event("change_deck", deck_id, socket) do
    selected_deck = Enum.find(socket.assigns.decks, &(&1.id == String.to_integer(deck_id)))
    {info, cards} = prepare_deck(selected_deck)

    {:noreply, assign(socket, selected_deck: selected_deck, cards: cards, info: info)}
  end

  def handle_event("change_num", %{"_target" => [card_id]} = data, socket) do
    new_num =
      data[card_id]
      |> String.to_integer()

    info = Map.put(socket.assigns.info, String.to_integer(card_id), new_num)

    {:ok, new_deck} =
      Decks.update_deck(socket.assigns.selected_deck, %{cards: Jason.encode!(info)})

    decks = Decks.decks_of_user(socket.assigns.user)

    {:noreply, assign(socket, info: info, selected_deck: new_deck, decks: decks)}
  end

  def prepare_deck(deck) do
    info = Jason.decode!(deck.cards, keys: &String.to_integer(&1))

    cards =
      Decks.all_card_in_ids(Map.keys(info))
      |> Enum.map(&Decks.parse_card_info/1)
      |> Enum.into(%{}, fn card -> {card.id, card} end)

    {info, cards}
  end
end
