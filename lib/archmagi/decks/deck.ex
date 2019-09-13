defmodule Archmagi.Decks.Deck do
  use Ecto.Schema
  import Ecto.Changeset

  schema "decks" do
    field(:cards, :string)
    field(:name, :string)
    belongs_to(:user, Archmagi.Users.User)

    timestamps()
  end

  @doc false
  def changeset(deck, attrs) do
    deck
    |> cast(attrs, [:name, :cards])
    |> validate_required([:name, :cards])
  end
end
