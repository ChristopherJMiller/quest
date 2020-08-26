defmodule Quest.Quest do
  use Ecto.Schema
  import Ecto.Changeset

  alias Quest.Party
  alias Quest.Server
  alias Quest.Post

  schema "quests" do
    belongs_to :server, Server
    belongs_to :party, Party
    field :title, :string
    field :description, :string
    field :location, :string
    field :level, :integer
    field :party_size, :integer
    field :coin_loot, :integer
    field :item_loot, :integer
    field :status, :integer
    has_one :post, Post
  end

  def valid_fields, do: [:title, :description, :location, :level, :party_size, :coin_loot, :item_loot, :party_id]

  def changeset(quest, params \\ %{}) do
    quest
    |> cast(params, [:server_id, :status | valid_fields()])
  end
end
