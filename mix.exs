defmodule Quest.MixProject do
  use Mix.Project

  def project do
    [
      app: :quest,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp extra_apps(:test), do: [:logger]
  defp extra_apps(_), do: [:logger, :nostrum]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: extra_apps(Mix.env()),
      mod: {Quest.Application, []}
    ]
  end

  defp aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:nostrum, "~> 0.4", runtime: false},
      {:mock, "~> 0.3.0", only: :test},
      {:excoveralls, "~> 0.10", only: :test}
    ]
  end
end
