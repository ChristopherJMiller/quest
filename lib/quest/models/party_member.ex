defmodule Quest.PartyMember do
  use Ecto.Schema
  import Ecto.Changeset

  alias Quest.Party
  alias Quest.Server

  schema "party_members" do
    belongs_to :server, Server
    field :user_id, :integer
    belongs_to :party, Party
  end

  def changeset(party_member, params \\ %{}) do
    party_member
    |> cast(params, [:server_id, :role_id, :user_id])
    |> unique_constraint(:server_id)
  end
end
