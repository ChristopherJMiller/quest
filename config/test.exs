import Config

config :quest, Quest.Repo,
  database: "quest_test",
  username: "test",
  password: "test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox