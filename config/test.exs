import Config

config :quest, Quest.Repo,
  database: "quest_test",
  username: "test",
  password: "test",
  hostname: System.get_env("DB_HOSTNAME", "localhost"),
  pool: Ecto.Adapters.SQL.Sandbox
