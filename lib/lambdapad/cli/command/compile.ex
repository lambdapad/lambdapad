defmodule Lambdapad.Cli.Command.Compile do
  @moduledoc """
  Compile CLI command is the by default command. Indeed, to run it you
  have avoid put a subcommand. It's based on the infile configuration
  global parameter to ensure you are reading the information from the
  correct place.
  """
  use Lambdapad.Cli.Command

  alias Lambdapad.{Blog, Cli, Config, Generate}
  alias Lambdapad.Generate.Sources

  @impl Lambdapad.Cli.Command
  def command(%{infile: filename, verbosity: loglevel, rawargs: rawargs}) do
    workdir = Cli.cwd!(filename)

    Application.put_env(:lambdapad, :workdir, workdir)
    Application.put_env(:lambdapad, :loglevel, loglevel)
    Sources.init()

    gt = Cli.print_level1("Reading configuration", filename)

    t = Cli.print_level2("Compiling", filename)
    {:ok, mod} = Blog.Base.compile(filename)
    Cli.print_level2_ok()

    {:ok, config} = Config.init(Blog.Base.get_configs(mod, rawargs), workdir)

    Cli.print_level2("Create directory")
    relative_output_dir = config["blog"]["output_dir"] || "site"
    Cli.print_level3(relative_output_dir)
    output_dir = Path.join([workdir, relative_output_dir])
    :ok = File.mkdir_p(output_dir)
    Cli.print_level2_ok()
    Cli.print_level1_ok(t)

    t = Cli.print_level1("Processing widgets")
    widgets = Generate.Widgets.process(Blog.Base.get_widgets(mod, config), config, mod, workdir)
    config = Map.put(config, "widgets", widgets)
    Cli.print_level1_ok(t)

    t = Cli.print_level1("Processing pages")

    config =
      Generate.Pages.process(Blog.Base.get_pages(mod, config), config, mod, workdir, output_dir)

    Cli.print_level1_ok(t)

    t = Cli.print_level1("Processing checks")
    apply_finish_checks(Blog.Base.get_checks(mod), config)
    Cli.print_level1_ok(t)

    t = Cli.print_level1("Processing assets")
    Generate.Assets.process(Blog.Base.get_assets(mod, config), workdir)
    Cli.print_level1_ok(t)

    Sources.terminate()
    :ok = Cli.done(gt)
  end

  defp apply_finish_checks(checks, config) do
    Enum.reduce(checks, config, fn
      {name, %{on: :finish, run: code}}, config ->
        Cli.print_level2("Checking", name)
        config = code.(config)
        Cli.print_level2_ok()
        config

      _, config ->
        config
    end)
  end
end
