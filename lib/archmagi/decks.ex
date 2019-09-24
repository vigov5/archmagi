defmodule Archmagi.Decks do
  @moduledoc """
  The Decks context.
  """

  import Ecto.Query, warn: false
  alias Archmagi.Repo

  alias Archmagi.Decks.Card

  @doc """
  Returns the list of cards.

  ## Examples

      iex> list_cards()
      [%Card{}, ...]

  """
  def list_cards do
    Repo.all(Card)
  end

  @doc """
  Gets a single card.

  Raises `Ecto.NoResultsError` if the Card does not exist.

  ## Examples

      iex> get_card!(123)
      %Card{}

      iex> get_card!(456)
      ** (Ecto.NoResultsError)

  """
  def get_card!(id), do: Repo.get!(Card, id)

  @doc """
  Creates a card.

  ## Examples

      iex> create_card(%{field: value})
      {:ok, %Card{}}

      iex> create_card(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_card(attrs \\ %{}) do
    %Card{}
    |> Card.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a card.

  ## Examples

      iex> update_card(card, %{field: new_value})
      {:ok, %Card{}}

      iex> update_card(card, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_card(%Card{} = card, attrs) do
    card
    |> Card.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Card.

  ## Examples

      iex> delete_card(card)
      {:ok, %Card{}}

      iex> delete_card(card)
      {:error, %Ecto.Changeset{}}

  """
  def delete_card(%Card{} = card) do
    Repo.delete(card)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking card changes.

  ## Examples

      iex> change_card(card)
      %Ecto.Changeset{source: %Card{}}

  """
  def change_card(%Card{} = card) do
    Card.changeset(card, %{})
  end

  alias Archmagi.Decks.Deck

  @doc """
  Returns the list of decks.

  ## Examples

      iex> list_decks()
      [%Deck{}, ...]

  """
  def list_decks do
    Repo.all(Deck)
  end

  @doc """
  Gets a single deck.

  Raises `Ecto.NoResultsError` if the Deck does not exist.

  ## Examples

      iex> get_deck!(123)
      %Deck{}

      iex> get_deck!(456)
      ** (Ecto.NoResultsError)

  """
  def get_deck!(id), do: Repo.get!(Deck, id)

  @doc """
  Creates a deck.

  ## Examples

      iex> create_deck(%{field: value})
      {:ok, %Deck{}}

      iex> create_deck(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_deck(user, attrs \\ %{}) do
    Ecto.build_assoc(user, :decks)
    |> Deck.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a deck.

  ## Examples

      iex> update_deck(deck, %{field: new_value})
      {:ok, %Deck{}}

      iex> update_deck(deck, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_deck(%Deck{} = deck, attrs) do
    deck
    |> Deck.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Deck.

  ## Examples

      iex> delete_deck(deck)
      {:ok, %Deck{}}

      iex> delete_deck(deck)
      {:error, %Ecto.Changeset{}}

  """
  def delete_deck(%Deck{} = deck) do
    Repo.delete(deck)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking deck changes.

  ## Examples

      iex> change_deck(deck)
      %Ecto.Changeset{source: %Deck{}}

  """
  def change_deck(%Deck{} = deck) do
    Deck.changeset(deck, %{})
  end

  def all_card_in_ids(ids) do
    card_query =
      from(
        c in Card,
        where: c.id in ^ids,
        select: c
      )

    Repo.all(card_query)
  end

  def parse_cards(deck) do
    mapping = Jason.decode!(deck.cards, keys: &String.to_integer(&1))

    all_card_in_ids(Map.keys(mapping))
    |> Enum.map(&parse_card_info/1)
    |> Enum.reduce([], fn card, acc -> acc ++ List.duplicate(card, mapping[card.id]) end)
  end

  def parse_card_info(%{costs: costs, effects: effects} = card) do
    {costs, []} = Code.eval_string(costs)
    {effects, []} = Code.eval_string(effects)
    %{card | costs: costs, effects: effects}
  end

  def create_default_deck(user, name) do
    cards =
      Repo.all(Card)
      |> Enum.map(&Map.get(&1, :id))
      |> Enum.reduce(%{}, fn x, acc -> Map.put(acc, x, 2) end)
      |> Jason.encode!()

    create_deck(user, %{cards: cards, name: name})
  end

  def decks_of_user(user) do
    Ecto.assoc(user, :decks)
    |> Repo.all()
  end
end
