defmodule Lambdapad.MixProject do
  use Mix.Project

  def project do
    [
      app: :lambdapad,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: Lambdapad.Cli],
      name: "Lambdapad",
      homepage_url: "https://lambdapad.com"
    ]
  end

  def application do
    [
      extra_applications: [:logger, :eex]
    ]
  end

  defp deps do
    [
      {:earmark, github: "manuel-rubio/earmark"},
      {:pockets, "~> 1.0"},
      {:erlydtl, "~> 0.14"},
      {:toml, "~> 0.6"}
    ]
  end
end
