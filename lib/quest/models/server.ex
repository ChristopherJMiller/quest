defmodule Quest.Server do
  use Ecto.Schema
  import Ecto.Changeset

  schema "servers" do
    field :server_id, :integer
    field :dm_role, :integer
    field :post_channel_id, :integer
  end

  def changeset(server, params \\ %{}) do
    server
    |> cast(params, [:server_id, :dm_role, :post_channel_id])
    |> unique_constraint(:server_id)
  end
end
