defmodule Lambdapad.Cli do
  require Logger

  alias Lambdapad.{Config, Generate, Http}

  @default_file "lambdapad.exs"
  @default_port 8080

  defp absname("."), do: File.cwd!()
  defp absname(dir), do: Path.absname(dir)

  defp cwd!(lambdapad_file) do
    unless File.exists?(lambdapad_file) do
      IO.puts("File #{lambdapad_file} not found.")
      System.halt(1)
    end

    absname(Path.dirname(lambdapad_file))
  end

  def main(args) do
    args
    |> parse_options()
    |> commands()
  end

  defp commands(%_{args: %{infile: nil}} = params) do
    commands(%{params | args: %{infile: @default_file}})
  end

  defp commands(%_{args: %{infile: lambdapad_file}, flags: %{verbosity: _loglevel}}) do
    workdir = cwd!(lambdapad_file)

    [{mod, _}] = Code.compile_file(lambdapad_file)
    {:ok, config} = Config.init(mod.config(), workdir)

    output_dir = Path.join([workdir, config["blog"]["output_dir"] || "site"])
    :ok = File.mkdir_p(output_dir)

    widgets = Generate.Widgets.process(mod.widgets(), config, mod, workdir)
    config = Map.put(config, "widgets", widgets)

    Generate.Pages.process(mod.pages(), config, mod, workdir, output_dir)
    Generate.Assets.process(mod.assets(), workdir)

    IO.puts("Ready!")
    :ok
  end

  defp commands({[:http], %_{args: %{infile: nil}} = params}) do
    commands({[:http], %{params | args: %{infile: @default_file}}})
  end

  defp commands({[:http], %_{args: %{infile: lambdapad_file}, options: %{port: port}}}) do
    workdir = cwd!(lambdapad_file)

    [{mod, _}] = Code.compile_file(lambdapad_file)
    {:ok, config} = Config.init(mod.config(), workdir)

    dir = Path.join([workdir, config["blog"]["output_dir"] || "site"])
    port = port || config["http"]["port"] || @default_port

    Http.start_server(port, dir)
    IO.gets("")
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
      ],
      subcommands: [
        http: [
          name: "http",
          about: "HTTP Server for fast checking",
          args: [
            infile: [
              value_name: "lambdapad.exs",
              help: "Specification to build your web site.",
              required: false,
              parser: :string
            ]
          ],
          options: [
            port: [
              value_name: "PORT",
              short: "-p",
              long: "--port",
              help: "Port where to listen, by default it is 8080",
              parser: fn(p) ->
                case Integer.parse(p) do
                  {port, ""} when port >= 1024 -> {:ok, port}
                  {port, ""} -> {:error, "port must be greater than 1024, #{port} is invalid"}
                  {_, _} -> {:error, "you have to provide a port number"}
                end
              end,
              required: false
            ]
          ]
        ]
      ]
    )
    |> Optimus.parse!(args)
  end
end
