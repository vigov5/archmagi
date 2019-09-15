defmodule Archmagi.Users.User do
  use Ecto.Schema
  use Pow.Ecto.Schema

  schema "users" do
    pow_user_fields()
    has_many(:decks, Archmagi.Decks.Deck)

    timestamps()
  end
end
