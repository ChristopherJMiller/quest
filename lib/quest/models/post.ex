defmodule Quest.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :server_id, :string
    field :post_id, :string
    field :quest_id, :integer
  end

  def changeset(post, params \\ %{}) do
    post
    |> cast(params, [:server_id, :post_id, :quest_id])
    |> unique_constraint(:server_id)
  end
end