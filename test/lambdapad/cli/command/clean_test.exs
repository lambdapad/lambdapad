defmodule Lambdapad.Cli.Command.CleanTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Lambdapad.Cli.Command.Clean

  @infile Path.join(__DIR__, "../../../support/cli_project/lambdapad.exs")
  @workdir Path.dirname(@infile)

  test "removes the output directory when it exists" do
    site_dir = Path.join(@workdir, "site")
    File.mkdir_p!(site_dir)
    File.write!(Path.join(site_dir, "dummy.html"), "content")

    capture_io(fn -> Clean.command(%{infile: @infile, rawargs: []}) end)

    refute File.exists?(site_dir)
  end

  test "does not crash when the output directory does not exist" do
    site_dir = Path.join(@workdir, "site")
    File.rm_rf!(site_dir)

    output = capture_io(fn -> Clean.command(%{infile: @infile, rawargs: []}) end)

    assert output =~ "Doesn't exist"
  end
end
