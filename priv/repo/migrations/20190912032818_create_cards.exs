defmodule Archmagi.Repo.Migrations.CreateCards do
  use Ecto.Migration

  def change do
    create table(:cards) do
      add :name, :string
      add :desc, :string
      add :costs, :text
      add :effects, :text

      timestamps()
    end

  end
end
