defmodule Quest.Repo do
  use Ecto.Repo,
    otp_app: :quest,
    adapter: Ecto.Adapters.Postgres
end
