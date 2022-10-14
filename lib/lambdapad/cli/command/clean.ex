defmodule Lambdapad.Cli.Command.Clean do
  @moduledoc """
  Clean CLI command is a way for cleaning the project. It's
  removing all of the generated files and kept clean the
  working directory.
  """
  use Lambdapad.Cli.Command
  alias Lambdapad.{Blog, Cli, Config}

  @impl Lambdapad.Cli.Command
  def options do
    [
      name: "clean",
      about: "Remove the output directory if exists",
      args: Cli.get_infile_options()
    ]
  end

  @impl Lambdapad.Cli.Command
  def command(%{infile: lambdapad_file, rawargs: rawargs}) do
    workdir = Cli.cwd!(lambdapad_file)

    gt = Cli.print_level1("Reading configuration", lambdapad_file)

    t = Cli.print_level2("Compiling", lambdapad_file)
    {:ok, mod} = Blog.Base.compile(lambdapad_file)
    Cli.print_level2_ok()

    {:ok, config} = Config.init(Blog.Base.get_configs(mod, rawargs), workdir)
    Cli.print_level2_ok()
    Cli.print_level1_ok(t)

    dir = Path.join([workdir, config["blog"]["output_dir"] || "site"])

    if File.exists?(dir) do
      t = Cli.print_level1("Remove directory", dir)
      File.rm_rf!(dir)
      Cli.print_level1_ok(t)
    else
      Cli.print_level1("Doesn't exist", dir)
    end

    :ok = Cli.done(gt)
  end
end
