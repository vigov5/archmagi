defmodule Archmagi.Decks.Card do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cards" do
    field(:costs, :string)
    field(:desc, :string)
    field(:effects, :string)
    field(:name, :string)

    timestamps()
  end

  @doc false
  def changeset(card, attrs) do
    card
    |> cast(attrs, [:name, :desc, :costs, :effects])
    |> validate_required([:name, :desc, :costs, :effects])
  end
end
