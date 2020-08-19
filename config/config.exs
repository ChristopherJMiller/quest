import Config

config :quest, ecto_repos: [Quest.Repo]

config :nostrum,
  token: System.get_env("TOKEN")

import_config "#{Mix.env()}.exs"
