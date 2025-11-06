defmodule Lambdapad.Cli.Command.New do
  @moduledoc """
  New command for CLI is providing a way to create a new website based on
  an existent template. You can see the available templates with the
  `templates` command.

  This is embedding the whole `templates` directory inside of the module,
  maybe it's not the most efficient way, but there's not a lot of templates
  at the moment.
  """
  use Lambdapad.Cli.Command
  alias Lambdapad.Cli

  Module.register_attribute(__MODULE__, :templates, accumulate: true)

  for "templates/" <> template <- Path.wildcard("templates/*") do
    files =
      Path.wildcard("templates/#{template}/**")
      |> Enum.filter(&File.regular?/1)

    for filepath <- files do
      @external_resource filepath
    end

    @templates {template,
                for filepath <- files do
                  file = String.replace_prefix(filepath, "templates/#{template}/", "")
                  {file, File.read!(filepath)}
                end}
  end

  defp get_template_files(template) do
    case List.keyfind(@templates, template, 0) do
      {^template, files} -> files
      nil -> nil
    end
  end

  @impl Lambdapad.Cli.Command
  def command(%{name: name, template: template, verbosity: loglevel}) do
    if File.exists?(name) do
      Cli.print_error("cannot create #{name} directory.")
      System.halt(1)
    end

    files = get_template_files(template)

    unless files do
      Cli.print_error("template #{template} not found.")
      System.halt(1)
    end

    Application.put_env(:lambdapad, :loglevel, loglevel)

    t = Cli.print_level1("Creating project", name)
    Cli.print_level2("Creating directory", name)
    File.mkdir_p!(name)
    Cli.print_level2_ok()
    Cli.print_level2("Creating files")

    Enum.each(files, fn {file, content} ->
      Cli.print_level3(file)
      filepath = Path.join([name, file])
      dirpath = Path.dirname(filepath)
      File.mkdir_p!(dirpath)
      File.write!(filepath, content)
    end)

    Cli.print_level2_ok()
    Cli.print_level1_ok(t)
  end

  @impl Lambdapad.Cli.Command
  def options do
    [
      name: "new",
      about: "New project based on a template, check templates command",
      args: [
        name: [
          value_name: "name",
          help: "Specify the name of the project to be created.",
          parser: :string,
          required: true
        ]
      ],
      flags: Cli.get_verbosity_options(),
      options: [
        template: [
          value_name: "NAME",
          short: "-t",
          long: "--template",
          help: "Choose the template name (use --list to see available)",
          parser: :string,
          required: false,
          default: "blog"
        ]
      ]
    ]
  end
end
