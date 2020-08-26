defmodule Quest.Repo.Migrations.CreateServer do
  use Ecto.Migration

  def change do
    create table(:servers) do
      add :server_id, :bigint
      add :dm_role, :bigint
    end
  end
end
