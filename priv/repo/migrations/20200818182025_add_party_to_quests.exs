defmodule Quest.Repo.Migrations.AddPartyToQuests do
  use Ecto.Migration

  def change do
    alter table(:quests) do
      add :party_id, :integer
    end
  end
end
