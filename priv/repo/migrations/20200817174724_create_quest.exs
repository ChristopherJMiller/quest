defmodule Quest.Repo.Migrations.CreateQuest do
  use Ecto.Migration

  def change do
    create table(:quests) do
      add :server_id, :string
      add :title, :string
      add :description, :string
      add :location, :string
      add :level, :integer
      add :party_size, :integer
      add :coin_loot, :integer
      add :item_loot, :integer
    end
  end
end
