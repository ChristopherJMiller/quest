defmodule Quest.Repo.Migrations.CreateServer do
  use Ecto.Migration

  def change do
    create table(:servers) do
      add :server_id, :string
      add :dm_role, :string
    end
  end
end
