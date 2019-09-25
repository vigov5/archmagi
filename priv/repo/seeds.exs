# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Archmagi.Repo.insert!(%Archmagi.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias Ecto.Changeset
alias Pow.Ecto.Schema.Password

password_hash = Password.pbkdf2_hash("admin123456")
admin =
  %Archmagi.Users.User{}
  |> Changeset.change(email: "admin@archmagi.com", password_hash: password_hash, role: "admin")
  |> Archmagi.Repo.insert!()

cards = [
  {"Wall", "+3 to wall", [bricks: 1], [{:me, {:add, :wall, 3}}]},
  {"Base", "+2 to tower", [bricks: 1], [{:me, {:add, :tower, 2}}]},
  {"Defence", "+6 to wall", [bricks: 3], [{:me, {:add, :wall, 2}}]},
  {"Reserve", "+8 to tower, -4 to wall", [bricks: 3], [{:me, {:add, :tower, 8}}, {:me, {:sub, :wall, 4}}]},
  {"Tower", "+5 to tower", [bricks: 5], [{:me, {:add, :tower, 5}}]},
  {"School", "+1 to quarry", [bricks: 8], [{:me, {:add, :quarry, 1}}]},
  {"Wain", "+8 to tower, -4 to enemy tower", [bricks: 10], [{:me, {:add, :tower, 8}}, {:you, {:sub, :tower, 4}}]},
  {"Great Wall", "+22 to wall", [bricks: 12], [{:me, {:add, :wall, 22}}]},
  {"Fort", "+20 to tower", [bricks: 18], [{:me, {:add, :tower, 20}}]},
  {"Babylon", "+32 to tower", [bricks: 39], [{:me, {:add, :tower, 32}}]},
  {"Archer", "2 damge", [recruits: 1], [{:you, {:attack_wall, 2}}]},
  {"Knight", "3 damge", [recruits: 2], [{:you, {:attack_wall, 3}}]}
]

cards
|> Enum.map(fn {name, desc, costs, effects} ->
  Archmagi.Repo.insert!(%Archmagi.Decks.Card{
    name: name,
    desc: desc,
    costs: Kernel.inspect(costs),
    effects: Kernel.inspect(effects)
  })
end)

Archmagi.Decks.create_default_deck(admin, "Default Deck")
