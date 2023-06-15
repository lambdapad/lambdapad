defmodule Lambdapad.Cli.Command.Gettext do
  use Lambdapad.Cli.Command

  alias Lambdapad.{Blog, Cli, Config}
  alias Lambdapad.Generate.Sources

  @impl Lambdapad.Cli.Command
  def options do
    [
      name: "gettext",
      about: "Extract all of the translations from templates",
      args: Cli.get_infile_options(),
      flags: Cli.get_verbosity_options()
    ]
  end

  @impl Lambdapad.Cli.Command
  def command(%{infile: filename, verbosity: loglevel, rawargs: rawargs}) do
    workdir = Cli.cwd!(filename)

    Application.put_env(:lambdapad, :workdir, workdir)
    Application.put_env(:lambdapad, :loglevel, loglevel)
    Sources.init()

    gt = Cli.print_level1("Reading configuration", filename)

    _ = Cli.print_level2("Compiling", filename)
    {:ok, mod} = Blog.Base.compile(filename)
    Cli.print_level2_ok()

    {:ok, config} = Config.init(Blog.Base.get_configs(mod, rawargs), workdir)

    Cli.print_level2("gettext path", config["blog"]["languages_path"])
    {:ok, _} = Application.ensure_all_started(:gettext)
    {:ok, _mod} = Lambdapad.Gettext.compile(config["blog"]["languages_path"])
    pot_files = extract()
    run_message_extraction(pot_files)

    Sources.terminate()
    :ok = Cli.done(gt)
  end

  defp extract do
    Gettext.Extractor.enable()
    # force compile
    Gettext.Extractor.pot_files(:lambdapad, [])
  after
    Gettext.Extractor.disable()
  end

  defp run_message_extraction(pot_files) do
    for {path, contents} <- pot_files do
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, contents)
      Mix.shell().info("Extracted #{Path.relative_to_cwd(path)}")
    end

    :ok
  end
end
