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
  {"Knight", "3 damge", [recruits: 2], [{:you, {:attack_wall, 3}}]},
  {"Rider", "4 damge", [recruits: 2], [{:you, {:attack_wall, 4}}]},
  {"Platoon", "6 damge", [recruits: 4], [{:you, {:attack_wall, 6}}]},
  {"Recurit", "+1 to dungeon", [recruits: 8], [{:me, {:add, :dungeon, 1}}]},
  {"Catapult", "12 damage", [recruits: 10], [{:you, {:attack_wall, 12}}]},
  {"Saboteur", "-4 enemy stocks", [recruits: 12], [{:you, {:sub, :bricks, 4}}, {:you, {:sub, :gems, 4}}, {:you, {:sub, :recruits, 4}}]},
  {"Clash", "-10 to enemy tower", [recruits: 18], [{:you, {:tower, 10}}]},
  {"Orc", "32 damage", [recruits: 28], [{:you, {:attack_wall, 32}}]},
  {"Brick Pile", "+8 to bricks", [gems: 4], [{:me, {:add, :bricks, 8}}]},
  {"Crystal Mine", "+8 to gems", [gems: 4], [{:me, {:add, :gems, 8}}]},
  {"Weapon Tech", "+8 to recruits", [gems: 4], [{:me, {:add, :recruits, 8}}]},
  {"Fake Brick", "-8 to enemy bricks", [gems: 4], [{:you, {:sub, :bricks, 8}}]},
  {"Alchemist Failure", "-8 to enemy gems", [gems: 4], [{:you, {:sub, :gems, 8}}]},
  {"Drop Weapon", "-8 to enemy recruits", [gems: 4], [{:you, {:sub, :recruits, 8}}]},
  {"Sorcerer", "+1 to magic", [gems: 8], [{:me, {:add, :magic, 1}}]},
  {"Dragon", "25 damage", [gems: 21], [{:you, {:attack_wall, 25}}]},
  {"Pixies", "+22 to tower", [gems: 22], [{:me, {:add, :tower, 22}}]},
  {"Curse", "+1 to all, -1 to all enemies", [gems: 45], [{:you, {:sub, :bricks, 1}}, {:you, {:sub, :gems, 1}}, {:you, {:sub, :recruits, 1}}, {:you, {:sub, :quarry, 1}}, {:you, {:sub, :magic, 1}}, {:you, {:sub, :dungeon, 1}}, {:you, {:sub, :wall, 1}}, {:you, {:sub, :tower, 1}}, {:me, {:add, :bricks, 1}}, {:me, {:add, :gems, 1}}, {:me, {:add, :recruits, 1}}, {:me, {:add, :quarry, 1}}, {:me, {:add, :magic, 1}}, {:me, {:add, :dungeon, 1}}, {:me, {:add, :wall, 1}}, {:me, {:add, :tower, 1}}]},
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
