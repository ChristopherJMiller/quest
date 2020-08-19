import Config

config :quest, Quest.Repo,
  database: System.get_env("DB_DATABASE"),
  username: System.get_env("DB_USER"),
  password: System.get_env("DB_PASS"),
  hostname: System.get_env("DB_HOSTNAME")