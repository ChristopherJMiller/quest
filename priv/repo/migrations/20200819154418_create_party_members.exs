defmodule Quest.Repo.Migrations.CreatePartyMembers do
  use Ecto.Migration

  def change do
    create table(:party_members) do
      add :server_id, :bigint
      add :user_id, :bigint
      add :party_id, :integer
    end
  end
end
