defmodule Quest.RepoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Quest.Repo

      import Ecto
      import Ecto.Query
      import Quest.RepoCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Quest.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Quest.Repo, {:shared, self()})
    end

    

    :ok
  end
end