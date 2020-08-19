defmodule Quest.Repo.Migrations.AddServerIdIndex do
  use Ecto.Migration

  def change do
    create index(:servers, [:server_id], comment: "Index Server Id")
    create index(:quests, [:server_id], comment: "Index Server Id")
  end
end
