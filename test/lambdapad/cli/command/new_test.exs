defmodule Lambdapad.Cli.Command.NewTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Lambdapad.Cli.Command.New

  test "creates a new project directory populated with the template files" do
    name =
      Path.join(System.tmp_dir!(), "lambdapad_new_test_#{System.unique_integer([:positive])}")

    capture_io(fn ->
      New.command(%{name: name, template: "blog", verbosity: 1})
    end)

    assert File.dir?(name)
    assert File.regular?(Path.join(name, "lambdapad.exs"))

    File.rm_rf!(name)
  end

  test "options/0 defaults the template to \"blog\"" do
    assert Lambdapad.Cli.Command.New.options()[:options][:template][:default] == "blog"
  end

  test "halts when the target directory already exists" do
    name =
      Path.join(System.tmp_dir!(), "lambdapad_new_test_#{System.unique_integer([:positive])}")

    File.mkdir_p!(name)

    assert catch_throw(
             capture_io(fn -> New.command(%{name: name, template: "blog", verbosity: 1}) end)
           ) == {:halt, 1}

    File.rm_rf!(name)
  end

  test "halts when the template does not exist" do
    name =
      Path.join(System.tmp_dir!(), "lambdapad_new_test_#{System.unique_integer([:positive])}")

    assert catch_throw(
             capture_io(fn ->
               New.command(%{name: name, template: "not-a-real-template", verbosity: 1})
             end)
           ) == {:halt, 1}

    refute File.exists?(name)
  end
end
