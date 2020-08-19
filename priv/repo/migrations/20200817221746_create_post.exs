defmodule Quest.Repo.Migrations.CreatePost do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :server_id, :string
      add :post_id, :string
      add :quest_id, :integer
    end
  end
end
