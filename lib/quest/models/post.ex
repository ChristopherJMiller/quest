defmodule Quest.Post do
  use Ecto.Schema
  import Ecto.Changeset

  alias Quest.Server
  alias Quest.Quest

  schema "posts" do
    field :post_id, :integer
    belongs_to :server, Server
    belongs_to :quest, Quest
  end

  def changeset(post, params \\ %{}) do
    post
    |> cast(params, [:server_id, :post_id, :quest_id])
    |> unique_constraint(:server_id)
  end
end
