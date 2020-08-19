defmodule Quest.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  def start(_type, _args) do
    Logger.info "running"
    children = [
      Quest.Repo,
      Quest.Bot
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Quest.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
