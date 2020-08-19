defmodule Quest.Server do
  use Ecto.Schema
  import Ecto.Changeset

  schema "servers" do
    field :server_id, :string
    field :dm_role, :string
    field :post_channel_id, :string
  end

  def changeset(server, params \\ %{}) do
    server
    |> cast(params, [:server_id, :dm_role, :post_channel_id])
    |> unique_constraint(:server_id)
  end
end