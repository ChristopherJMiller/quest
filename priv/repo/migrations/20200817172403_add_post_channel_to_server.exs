defmodule Quest.Repo.Migrations.AddPostChannelToServer do
  use Ecto.Migration

  def change do
    alter table(:servers) do
      add :post_channel_id, :string
    end
  end
end
