defmodule Lambdapad.Cli.Command.GettextTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Lambdapad.Cli.Command.Gettext, as: GettextCommand

  @infile Path.join(__DIR__, "../../../support/gettext_cli_project/lambdapad.exs")
  @workdir Path.dirname(@infile)
  @gettext_dir Path.join(@workdir, "gettext")

  setup do
    on_exit(fn -> File.rm_rf!(@gettext_dir) end)
    :ok
  end

  test "extracts gettext calls into the default `gettext` directory and generates PO files per language" do
    File.rm_rf!(@gettext_dir)

    capture_io(fn ->
      GettextCommand.command(%{infile: @infile, verbosity: 1, rawargs: []})
    end)

    assert File.regular?(Path.join(@gettext_dir, "default.pot"))
    assert File.read!(Path.join(@gettext_dir, "default.pot")) =~ "Welcome to my blog"

    assert File.regular?(Path.join(@gettext_dir, "en/LC_MESSAGES/default.po"))
    assert File.regular?(Path.join(@gettext_dir, "es/LC_MESSAGES/default.po"))
  end
end
