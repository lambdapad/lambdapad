defmodule Lambdapad.Cli do

  alias Lambdapad.{Config, Generate, Http}
  alias Lambdapad.Generate.Sources

  @default_file "lambdapad.exs"
  @default_port 8080
  @default_verbosity 1

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

  defp commands(%_{args: %{infile: lambdapad_file}, flags: %{verbosity: loglevel}}) do
    workdir = cwd!(lambdapad_file)

    Application.put_env(:lambdapad, :workdir, workdir)
    Application.put_env(:lambdapad, :loglevel, loglevel)
    Sources.init()

    gt = print_level1("Reading configuration", lambdapad_file)

    t = print_level2("Compiling", lambdapad_file)
    [{mod, _}] = Code.compile_file(lambdapad_file)
    print_level2_ok()

    {:ok, config} = Config.init(mod.config(), workdir)

    print_level2("Create directory")
    relative_output_dir = config["blog"]["output_dir"] || "site"
    print_level3(relative_output_dir)
    output_dir = Path.join([workdir, relative_output_dir])
    :ok = File.mkdir_p(output_dir)
    print_level2_ok()
    print_level1_ok(t)

    t = print_level1("Processing widgets")
    widgets = Generate.Widgets.process(mod.widgets(), config, mod, workdir)
    config = Map.put(config, "widgets", widgets)
    print_level1_ok(t)

    t = print_level1("Processing pages")
    Generate.Pages.process(mod.pages(), config, mod, workdir, output_dir)
    print_level1_ok(t)

    t = print_level1("Processing assets")
    Generate.Assets.process(mod.assets(), workdir)
    print_level1_ok(t)

    gt = System.system_time(:millisecond) - gt
    IO.puts([IO.ANSI.blue(), "Done (#{gt / 1000}s)", IO.ANSI.reset()])
    :ok
  end

  defp commands({subcommand, %_{args: %{infile: nil}} = params}) do
    commands({subcommand, %{params | args: %{infile: @default_file}}})
  end

  defp commands({[:clean], %_{args: %{infile: lambdapad_file}}}) do
    workdir = cwd!(lambdapad_file)

    gt = print_level1("Reading configuration", lambdapad_file)

    t = print_level2("Compiling", lambdapad_file)
    [{mod, _}] = Code.compile_file(lambdapad_file)
    print_level2_ok()

    {:ok, config} = Config.init(mod.config(), workdir)
    print_level2_ok()
    print_level1_ok(t)

    dir = Path.join([workdir, config["blog"]["output_dir"] || "site"])
    if File.exists?(dir) do
      t = print_level1("Remove directory", dir)
      File.rm_rf!(dir)
      print_level1_ok(t)
    else
      print_level1("Doesn't exist", dir)
    end

    gt = System.system_time(:millisecond) - gt
    IO.puts([IO.ANSI.blue(), "Done (#{gt / 1000}s)", IO.ANSI.reset()])
    :ok
  end

  defp commands({[:http], %_{args: %{infile: lambdapad_file}, options: %{port: port}} = params}) do
    workdir = cwd!(lambdapad_file)

    [{mod, _}] = Code.compile_file(lambdapad_file)
    {:ok, config} = Config.init(mod.config(), workdir)

    dir = Path.join([workdir, config["blog"]["output_dir"] || "site"])
    port = port || config["http"]["port"] || @default_port

    Http.start_server(port, dir)
    IO.puts([IO.ANSI.green(), "options", IO.ANSI.reset(), ": [q]uit or [r]ecompile"])
    if IO.gets("") == "r\n" do
      commands(%{params | options: %{}, flags: %{verbosity: @default_verbosity}})
      commands({[:http], params})
    end
  end

  def print_error(msg) do
    IO.puts([IO.ANSI.red(), " error: ", msg, IO.ANSI.reset()])
  end

  def print_level1(name) do
    if Application.get_env(:lambdapad, :loglevel, 1) >= 2 do
      IO.puts([IO.ANSI.blue(), "*", IO.ANSI.reset(), " ", name, ":"])
    else
      IO.write([
        IO.ANSI.blue(), "*", IO.ANSI.reset(), " ", name, ":\n  ",
      ])
    end
    System.system_time(:millisecond)
  end

  def print_level1(name, annex) do
    if Application.get_env(:lambdapad, :loglevel, 1) >= 2 do
      IO.puts([
        IO.ANSI.blue(), "*", IO.ANSI.reset(), " ", name, ": ",
        IO.ANSI.green(), annex, IO.ANSI.reset()
      ])
    else
      IO.write([
        IO.ANSI.blue(), "*", IO.ANSI.reset(), " ", name, ": ",
        IO.ANSI.green(), annex, IO.ANSI.reset(), "\n  "
      ])
    end
    System.system_time(:millisecond)
  end

  def print_level1_ok(t) do
    t = System.system_time(:millisecond) - t
    if Application.get_env(:lambdapad, :loglevel, 1) >= 2 do
      IO.puts([IO.ANSI.blue(), "  Done (#{t / 1000}s)", IO.ANSI.reset()])
    else
      IO.puts([IO.ANSI.blue(), "\n  Done (#{t / 1000}s)", IO.ANSI.reset()])
    end
  end

  def print_level2(name) do
    if Application.get_env(:lambdapad, :loglevel, 1) >= 2 do
      IO.write([IO.ANSI.blue(), "  -", IO.ANSI.reset(), " ", name, " "])
    else
      IO.write([IO.ANSI.green(), ".", IO.ANSI.reset()])
    end
    System.system_time(:millisecond)
  end

  def print_level2(name, annex) do
    if Application.get_env(:lambdapad, :loglevel, 1) >= 2 do
      IO.write([
        IO.ANSI.blue(), "  -", IO.ANSI.reset(), " ", name, " ",
        IO.ANSI.yellow(), annex, IO.ANSI.reset(), " "])
    else
      IO.write([IO.ANSI.green(), ".", IO.ANSI.reset()])
    end
    System.system_time(:millisecond)
  end

  def print_level2_warn(msg) do
    if Application.get_env(:lambdapad, :loglevel, 1) >= 2 do
      IO.write([
        "\n    ", IO.ANSI.yellow(), "warning ", IO.ANSI.reset(), msg, "\n    "
      ])
    end
  end

  def print_level2_ok() do
    case Application.get_env(:lambdapad, :loglevel, 1) do
      2 -> IO.puts([IO.ANSI.green(), " ok", IO.ANSI.reset()])
      n when n >= 3 -> IO.write("\n")
      _ -> :ok
    end
  end

  def print_level3(name) do
    if Application.get_env(:lambdapad, :loglevel, 1) >= 3 do
      IO.write(["\n    ", IO.ANSI.blue(), "- ", IO.ANSI.reset(), name])
    else
      IO.write([IO.ANSI.blue(), ".", IO.ANSI.reset()])
    end
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
          multiple: true,
          default: 1
        ]
      ],
      subcommands: [
        clean: [
          name: "clean",
          about: "Remove the output directory if exists",
          args: [
            infile: [
              value_name: "lambdapad.exs",
              help: "Specification to build your web site.",
              required: false,
              parser: :string
            ]
          ]
        ],
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
