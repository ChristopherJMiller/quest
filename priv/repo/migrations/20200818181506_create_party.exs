defmodule Quest.Repo.Migrations.CreateParty do
  use Ecto.Migration

  def change do
    create table(:parties) do
      add :server_id, :bigint
      add :role_id, :bigint
    end
  end
end
