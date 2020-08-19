defmodule Quest.Repo.Migrations.CreatePartyMembers do
  use Ecto.Migration

  def change do
    create table(:party_members) do
      add :server_id, :string
      add :user_id, :string
      add :role_id, :string
    end
  end
end
