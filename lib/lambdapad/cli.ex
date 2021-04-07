defmodule Lambdapad.Cli do
  require Logger

  alias Lambdapad.{Config, Generate}

  @default_file "lambdapad.exs"

  defp absname("."), do: File.cwd!()
  defp absname(dir), do: Path.absname(dir)

  def main(args) do
    args
    |> parse_options()
    |> commands()
  end

  def commands(%_{args: %{infile: nil}} = params) do
    commands(%{params | args: %{infile: @default_file}})
  end

  def commands(%_{args: %{infile: lambdapad_file}, flags: %{verbosity: _loglevel}}) do
    unless File.exists?(lambdapad_file) do
      IO.puts("File #{lambdapad_file} not found.")
      System.halt(1)
    end

    [{mod, _}] = Code.compile_file(lambdapad_file)
    workdir = absname(Path.dirname(lambdapad_file))
    {:ok, config} = Config.init(mod.config(), workdir)

    output_dir = Path.join([workdir, config[:output_dir] || "site"])
    :ok = File.mkdir_p(output_dir)

    widgets = Generate.Widgets.process(mod.widgets(), config, mod, workdir)
    config = Map.put(config, "widgets", widgets)

    Generate.Pages.process(mod.pages(), config, mod, workdir, output_dir)
    Generate.Assets.process(mod.assets(), workdir)

    IO.puts("Ready!")
    :ok
  end

  defp parse_options(args) do
    spec = Config.lambdapad_metainfo()["lambdapad"]
    Optimus.new!(
      description: spec["name"],
      version: spec["vsn"],
      about: spec["description"],
      allow_unknown_args: false,
      parse_double_dash: true,
      args: [
        infile: [
          value_name: "lambdapad.exs",
          help: "Specification to build your web site.",
          required: false,
          parser: :string
        ]
      ],
      flags: [
        verbosity: [
          short: "-v",
          help: "Verbosity level.",
          multiple: true
        ]
      ]
    )
    |> Optimus.parse!(args)
  end
end
