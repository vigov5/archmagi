defmodule Archmagi.DecksTest do
  use Archmagi.DataCase

  alias Archmagi.Decks

  describe "cards" do
    alias Archmagi.Decks.Card

    @valid_attrs %{
      costs: "some costs",
      desc: "some desc",
      effects: "some effects",
      name: "some name"
    }
    @update_attrs %{
      costs: "some updated costs",
      desc: "some updated desc",
      effects: "some updated effects",
      name: "some updated name"
    }
    @invalid_attrs %{costs: nil, desc: nil, effects: nil, name: nil}

    def card_fixture(attrs \\ %{}) do
      {:ok, card} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Decks.create_card()

      card
    end

    test "list_cards/0 returns all cards" do
      card = card_fixture()
      assert Decks.list_cards() == [card]
    end

    test "get_card!/1 returns the card with given id" do
      card = card_fixture()
      assert Decks.get_card!(card.id) == card
    end

    test "create_card/1 with valid data creates a card" do
      assert {:ok, %Card{} = card} = Decks.create_card(@valid_attrs)
      assert card.costs == "some costs"
      assert card.desc == "some desc"
      assert card.effects == "some effects"
      assert card.name == "some name"
    end

    test "create_card/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Decks.create_card(@invalid_attrs)
    end

    test "update_card/2 with valid data updates the card" do
      card = card_fixture()
      assert {:ok, %Card{} = card} = Decks.update_card(card, @update_attrs)
      assert card.costs == "some updated costs"
      assert card.desc == "some updated desc"
      assert card.effects == "some updated effects"
      assert card.name == "some updated name"
    end

    test "update_card/2 with invalid data returns error changeset" do
      card = card_fixture()
      assert {:error, %Ecto.Changeset{}} = Decks.update_card(card, @invalid_attrs)
      assert card == Decks.get_card!(card.id)
    end

    test "delete_card/1 deletes the card" do
      card = card_fixture()
      assert {:ok, %Card{}} = Decks.delete_card(card)
      assert_raise Ecto.NoResultsError, fn -> Decks.get_card!(card.id) end
    end

    test "change_card/1 returns a card changeset" do
      card = card_fixture()
      assert %Ecto.Changeset{} = Decks.change_card(card)
    end
  end

  describe "decks" do
    alias Archmagi.Decks.Deck

    @valid_attrs %{cards: "some cards", name: "some name"}
    @update_attrs %{cards: "some updated cards", name: "some updated name"}
    @invalid_attrs %{cards: nil, name: nil}

    def deck_fixture(attrs \\ %{}) do
      {:ok, deck} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Decks.create_deck()

      deck
    end

    test "list_decks/0 returns all decks" do
      deck = deck_fixture()
      assert Decks.list_decks() == [deck]
    end

    test "get_deck!/1 returns the deck with given id" do
      deck = deck_fixture()
      assert Decks.get_deck!(deck.id) == deck
    end

    test "create_deck/1 with valid data creates a deck" do
      assert {:ok, %Deck{} = deck} = Decks.create_deck(@valid_attrs)
      assert deck.cards == "some cards"
      assert deck.name == "some name"
    end

    test "create_deck/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Decks.create_deck(@invalid_attrs)
    end

    test "update_deck/2 with valid data updates the deck" do
      deck = deck_fixture()
      assert {:ok, %Deck{} = deck} = Decks.update_deck(deck, @update_attrs)
      assert deck.cards == "some updated cards"
      assert deck.name == "some updated name"
    end

    test "update_deck/2 with invalid data returns error changeset" do
      deck = deck_fixture()
      assert {:error, %Ecto.Changeset{}} = Decks.update_deck(deck, @invalid_attrs)
      assert deck == Decks.get_deck!(deck.id)
    end

    test "delete_deck/1 deletes the deck" do
      deck = deck_fixture()
      assert {:ok, %Deck{}} = Decks.delete_deck(deck)
      assert_raise Ecto.NoResultsError, fn -> Decks.get_deck!(deck.id) end
    end

    test "change_deck/1 returns a deck changeset" do
      deck = deck_fixture()
      assert %Ecto.Changeset{} = Decks.change_deck(deck)
    end
  end
end
