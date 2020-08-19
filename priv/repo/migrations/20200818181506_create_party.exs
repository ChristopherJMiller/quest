defmodule Quest.Repo.Migrations.CreateParty do
  use Ecto.Migration

  def change do
    create table(:parties) do
      add :server_id, :string
      add :role_id, :string
    end
  end
end
