defmodule Quest.Party do
  use Ecto.Schema
  import Ecto.Changeset

  schema "parties" do
    field :server_id, :string
    field :role_id, :string
  end

  def changeset(party, params \\ %{}) do
    party
    |> cast(params, [:server_id, :role_id])
    |> unique_constraint(:server_id)
  end
end