defmodule Quest.Repo.Migrations.AddStatusToQuests do
  use Ecto.Migration

  def change do
    alter table(:quests) do
      add :status, :integer
    end
  end
end
