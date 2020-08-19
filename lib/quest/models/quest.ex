defmodule Quest.Quest do
  use Ecto.Schema
  import Ecto.Changeset

  schema "quests" do
    field :server_id, :string
    field :title, :string
    field :description, :string
    field :location, :string
    field :level, :integer
    field :party_size, :integer
    field :coin_loot, :integer
    field :item_loot, :integer
    field :status, :integer
    field :party_id, :integer
  end

  def valid_fields, do: [:title, :description, :location, :level, :party_size, :coin_loot, :item_loot, :party_id]

  def changeset(quest, params \\ %{}) do
    quest
    |> cast(params, [:server_id, :status | valid_fields()])
    |> unique_constraint(:server_id)
  end
end