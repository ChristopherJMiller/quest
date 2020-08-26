defmodule Quest.Party do
  use Ecto.Schema
  import Ecto.Changeset

  alias Quest.Server

  schema "parties" do
    belongs_to :server, Server
    field :role_id, :integer
  end

  def changeset(party, params \\ %{}) do
    party
    |> cast(params, [:server_id, :role_id])
    |> unique_constraint(:server_id)
  end
end
