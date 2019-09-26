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

Archmagi.Decks.create_default_deck(admin, "Default Deck")
