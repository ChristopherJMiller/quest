defmodule Quest.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  defp get_children(:test), do: [Quest.Repo]
  defp get_children(_), do: [Quest.Repo, Quest.Bot]

  def start(_type, _args) do
    Logger.info "running"
    children = get_children(Mix.env())

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Quest.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
