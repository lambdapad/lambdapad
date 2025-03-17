defmodule Lambdapad.Cli do
  @moduledoc """
  Generic module in charge of handling the CLI, or Command Line
  Interface. The concerns for this module are regarding the
  handling of the input arguments, the output for the CLI and
  the flow of the application, it's:

  1. Reading and processing the configuration.
  2. Compiling the definition file (i.e. `lambdapad.exs`)
  3. Processing the widgets.
  4. Processing the pages.
  5. Processing the checks.
  6. Processing the assets.
  """
  alias Lambdapad.Cli.Command
  alias Lambdapad.Config

  @default_verbosity 1

  defp absname("."), do: File.cwd!()
  defp absname(dir), do: Path.absname(dir)

  @doc """
  Returns the absolute path for the current working path.
  """
  @spec cwd!(String.t()) :: String.t()
  def cwd!(lambdapad_file) do
    unless File.exists?(lambdapad_file) do
      IO.puts("File #{lambdapad_file} not found.")
      System.halt(1)
    end

    absname(Path.dirname(lambdapad_file))
  end

  @doc """
  Gives the default file depending on the current directory. If the file
  `index.erl` exists, then it's returned as the default file, otherwise the
  `lambdapad.exs` is returned.
  """
  @spec default_file() :: String.t()
  def default_file do
    if File.exists?("index.erl") do
      "index.erl"
    else
      "lambdapad.exs"
    end
  end

  @doc false
  @spec main(any) :: none | :ok
  def main(args) do
    args
    |> parse_options()
    |> commands(args)
  end

  defp commands(%_{} = params, rawargs) do
    commands({[:compile], params}, rawargs)
  end

  defp commands({[subcommand], %_{} = params}, rawargs) do
    data =
      params.args
      |> Map.merge(params.flags)
      |> Map.merge(params.options)
      |> Map.put(:infile, params.args[:infile] || default_file())
      |> Map.put(:rawargs, rawargs)

    command(to_string(subcommand), data)
  end

  defp command(subcommand, data) do
    subcommand_str = Macro.camelize(String.replace(subcommand, "-", "_"))
    mod = Module.concat([Lambdapad.Cli.Command, subcommand_str])
    Code.ensure_loaded(mod)

    if function_exported?(mod, :command, 1) do
      mod.command(data)
    else
      print_error("unknown subcommand #{subcommand}")
      System.halt(1)
    end
  end

  @doc """
  Prints the `Done` message with the corresponding time spent.
  """
  @spec done(pos_integer()) :: :ok
  def done(gt) do
    gt = System.system_time(:millisecond) - gt
    :ok = IO.puts([IO.ANSI.blue(), "Done (#{gt / 1000}s)", IO.ANSI.reset()])
  end

  @doc """
  Prints an error passed as parameter ensuring it's printed in the correct
  color and with the correct format.
  """
  @spec print_error(String.t()) :: :ok
  def print_error(msg) do
    :ok = IO.puts([IO.ANSI.red(), " error: ", msg, IO.ANSI.reset()])
  end

  @doc """
  Returns if the loglevel is higher than the number provided.
  """
  @spec loglevel_equal_or_greater_than?(pos_integer()) :: boolean()
  def loglevel_equal_or_greater_than?(loglevel) when loglevel >= 1 do
    Application.get_env(:lambdapad, :loglevel, 1) >= loglevel
  end

  @doc """
  Print a message in the loglevel 1. It's ensuring that it's possible to be
  printed based on the content of the loglevel information and depending on
  that information is printing the whole detailed information string
  passed as parameter or only a blue dot. It returns the current time
  or timestamp.
  """
  @spec print_level1(String.t()) :: pos_integer()
  def print_level1(name) do
    if loglevel_equal_or_greater_than?(2) do
      IO.puts([IO.ANSI.blue(), "*", IO.ANSI.reset(), " ", name, ":"])
    else
      IO.write([
        IO.ANSI.blue(),
        "*",
        IO.ANSI.reset(),
        " ",
        name,
        ":\n  "
      ])
    end

    System.system_time(:millisecond)
  end

  @doc """
  Similar to `print_level1/1` but it's adding an `annex`, I mean, it's
  printing extra information. It returns the current time or timestamp.
  """
  @spec print_level1(String.t(), String.t()) :: pos_integer()
  def print_level1(name, annex) do
    if loglevel_equal_or_greater_than?(2) do
      IO.puts([
        IO.ANSI.blue(),
        "*",
        IO.ANSI.reset(),
        " ",
        name,
        ": ",
        IO.ANSI.green(),
        annex,
        IO.ANSI.reset()
      ])
    else
      IO.write([
        IO.ANSI.blue(),
        "*",
        IO.ANSI.reset(),
        " ",
        name,
        ": ",
        IO.ANSI.green(),
        annex,
        IO.ANSI.reset(),
        "\n  "
      ])
    end

    System.system_time(:millisecond)
  end

  @doc """
  Prints the ending of the level1 task. It's getting the initial timestamp
  to calculate the time spent.
  """
  def print_level1_ok(t) do
    t = System.system_time(:millisecond) - t

    if loglevel_equal_or_greater_than?(2) do
      IO.puts([IO.ANSI.blue(), "  Done (#{t / 1000}s)", IO.ANSI.reset()])
    else
      IO.puts([IO.ANSI.blue(), "\n  Done (#{t / 1000}s)", IO.ANSI.reset()])
    end
  end

  @doc """
  Prints a level2 message if the loglevel is big enough to show it. It's
  also returning the current time or timestamp.
  """
  def print_level2(name) do
    if loglevel_equal_or_greater_than?(2) do
      IO.write([IO.ANSI.blue(), "  -", IO.ANSI.reset(), " ", name, " "])
    else
      IO.write([IO.ANSI.green(), ".", IO.ANSI.reset()])
    end

    System.system_time(:millisecond)
  end

  @doc """
  Prints the level2 message with an annex if the loglevel is big enough.
  It's also returning the current time or timestamp.
  """
  def print_level2(name, annex) do
    if loglevel_equal_or_greater_than?(2) do
      IO.write([
        IO.ANSI.blue(),
        "  -",
        IO.ANSI.reset(),
        " ",
        name,
        " ",
        IO.ANSI.yellow(),
        annex,
        IO.ANSI.reset(),
        " "
      ])
    else
      IO.write([IO.ANSI.green(), ".", IO.ANSI.reset()])
    end

    System.system_time(:millisecond)
  end

  @doc """
  Prints the level2 error message with information about the row,
  col, filename, error name and error description. It's printed
  because it's in the higher level of the loglevel.
  """
  @spec print_level2_error(String.t(), pos_integer(), pos_integer(), iodata(), iodata()) :: :ok
  def print_level2_error(filename, row, col, name, description) do
    IO.write([
      IO.ANSI.reset(),
      "  ",
      IO.ANSI.red(),
      filename,
      ":#{row}:#{col}: ",
      IO.ANSI.yellow(),
      name,
      IO.ANSI.reset(),
      ": ",
      description,
      "\n"
    ])
  end

  @doc """
  Prints a level2 warning if the loglevel is big enough to show it.
  """
  @spec print_level2_warn(iodata()) :: :ok
  def print_level2_warn(msg) do
    if loglevel_equal_or_greater_than?(2) do
      IO.write([
        "\n    ",
        IO.ANSI.yellow(),
        "warning ",
        IO.ANSI.reset(),
        msg,
        "\n    "
      ])
    end

    :ok
  end

  @doc """
  Prints a level2 end of task if the loglevel is big enough to show it.
  """
  @spec print_level2_ok() :: :ok
  def print_level2_ok do
    case Application.get_env(:lambdapad, :loglevel, 1) do
      2 -> IO.puts([IO.ANSI.green(), " ok", IO.ANSI.reset()])
      n when n >= 3 -> IO.write("\n")
      _ -> :ok
    end
  end

  @doc """
  Prints a level3 message if the loglevel is big enough to show it.
  """
  def print_level3(name) do
    if loglevel_equal_or_greater_than?(3) do
      IO.write(["\n    ", IO.ANSI.blue(), "- ", IO.ANSI.reset(), name])
    else
      IO.write([IO.ANSI.blue(), ".", IO.ANSI.reset()])
    end
  end

  @doc """
  When we need to output a text in multi-line way, but only if level3
  is available to present data.
  """
  def print_level3_multiline(text) do
    if loglevel_equal_or_greater_than?(3) do
      text =
        text
        |> String.trim()
        |> String.replace(~r/\n/, "\n    | ")

      IO.write(["\n    | ", IO.ANSI.blue(), "- ", IO.ANSI.reset(), text])
    end
  end

  @doc """
  Infile configuration option. This configuration is about the default
  input file we are using to retrieve the information to generate the
  website.
  """
  def get_infile_options do
    [
      infile: [
        value_name: default_file(),
        help: "Specification to build your web site.",
        required: false,
        parser: :string
      ]
    ]
  end

  @doc """
  Verbosity configuration parameter.
  """
  def get_verbosity_options do
    [
      verbosity: [
        short: "-v",
        help: "Verbosity level.",
        multiple: true,
        default: @default_verbosity
      ]
    ]
  end

  defp parse_options(args) do
    spec = Config.lambdapad_metainfo()["lambdapad"]

    Optimus.new!(
      description: spec["name"],
      version: spec["vsn"],
      about: spec["description"],
      allow_unknown_args: false,
      parse_double_dash: true,
      args: get_infile_options(),
      flags: get_verbosity_options(),
      subcommands:
        Command.get_modules()
        |> Enum.map(&Command.get_options/1)
        |> Enum.reject(&is_nil/1)
    )
    |> Optimus.parse!(args)
  end
end
