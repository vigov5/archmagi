admin = Archmagi.Repo.get!(Archmagi.Users.User, 1)
Archmagi.Decks.create_default_deck(admin, "Default Deck")
