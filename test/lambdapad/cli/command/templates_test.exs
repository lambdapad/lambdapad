defmodule Lambdapad.Cli.Command.TemplatesTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Lambdapad.Cli.Command.Templates

  test "command/1 lists the available templates" do
    output = capture_io(fn -> Templates.command(%{}) end)

    assert output =~ "Available templates: "
    assert output =~ "blog"
    assert output =~ "erlblog"
  end

  test "options/0 declares the templates subcommand" do
    assert Templates.options()[:name] == "templates"
  end
end
