defmodule Lambdapad.MixProject do
  use Mix.Project

  def project do
    [
      name: "Lambdapad",
      description: "Static website generator",
      app: :lambdapad,
      version: "0.9.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript(),
      name: "Lambdapad",
      homepage_url: "https://lambdapad.com"
    ]
  end

  defp escript do
    if Mix.env() == :dev and is_nil(System.get_env("IGNORE_BUILD_WARNING")) do
      IO.warn(
        """
        This script generated is including dependencies like ex_check,
        dialyxir, credo, and all of the development tools which aren't
        needed for production, use this command instead for generating
        the correct build:

        MIX_ENV=prod mix escript.build
        """,
        []
      )
    end

    [
      main_module: Lambdapad.Cli,
      name: "lpad"
    ]
  end

  def application do
    [
      extra_applications: [:logger, :eex, :inets, :ssl]
    ]
  end

  defp deps do
    [
      {:earmark, "~> 1.4"},
      {:erlydtl, github: "manuel-rubio/erlydtl"},
      {:pockets, "~> 1.0"},
      {:toml, "~> 0.6"},
      {:optimus, "~> 0.3"},
      {:cowboy, "~> 2.8"},
      {:floki, "~> 0.30"},
      {:phoenix_html, "~> 3.3"},

      # dependencies only for check, use `MIX_ENV=prod mix escript.build` for
      # generating the production script avoiding including these.
      {:ex_check, "~> 0.14", runtime: false, only: :dev},
      {:dialyxir, "~> 1.2", runtime: false, only: :dev},
      {:doctor, "~> 0.19", runtime: false, only: :dev},
      {:credo, "~> 1.6", runtime: false, only: :dev}
    ]
  end
end
