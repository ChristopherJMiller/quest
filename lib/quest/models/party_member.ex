defmodule Quest.PartyMember do
  use Ecto.Schema
  import Ecto.Changeset

  schema "party_members" do
    field :server_id, :string
    field :user_id, :string
    field :role_id, :string
  end

  def changeset(party_member, params \\ %{}) do
    party_member
    |> cast(params, [:server_id, :role_id, :user_id])
    |> unique_constraint(:server_id)
  end
end