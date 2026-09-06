defmodule Lambdapad.Cli.Command.HttpTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Lambdapad.Cli.Command.Http

  @infile Path.join(__DIR__, "../../../support/cli_project/lambdapad.exs")

  test "starts the server on the given port and exits cleanly on any input but r" do
    port = 8000 + rem(System.unique_integer([:positive]), 1000)
    params = %{infile: @infile, port: port, verbosity: 1, rawargs: []}

    output = capture_io("q\n", fn -> assert :ok = Http.command(params) end)

    assert output =~ "HTTP Server on"
    assert output =~ "options"
  end

  test "options/0 declares the port option with a parser rejecting low ports" do
    parser = Http.options()[:options][:port][:parser]

    assert parser.("9090") == {:ok, 9090}
    assert {:error, _} = parser.("80")
    assert {:error, _} = parser.("not-a-number")
  end
end
