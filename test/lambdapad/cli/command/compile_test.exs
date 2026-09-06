defmodule Lambdapad.Cli.Command.CompileTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Lambdapad.Cli.Command.Compile

  @infile Path.join(__DIR__, "../../../support/cli_project/lambdapad.exs")
  @workdir Path.dirname(@infile)

  test "builds the whole site: creates the output directory and renders the pages" do
    File.rm_rf!(Path.join(@workdir, "site"))

    capture_io(fn ->
      Compile.command(%{infile: @infile, verbosity: 1, rawargs: []})
    end)

    output_file = Path.join(@workdir, "site/index.html")
    assert File.regular?(output_file)
    assert File.read!(output_file) =~ "Hello from the compile command test."

    File.rm_rf!(Path.join(@workdir, "site"))
  end
end
