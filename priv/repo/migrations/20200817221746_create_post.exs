defmodule Quest.Repo.Migrations.CreatePost do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :server_id, :bigint
      add :post_id, :bigint
      add :quest_id, :bigint
    end
  end
end
