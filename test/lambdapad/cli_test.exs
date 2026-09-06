defmodule Lambdapad.CliTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Lambdapad.Cli

  defp with_loglevel(level, fun) do
    previous = Application.get_env(:lambdapad, :loglevel)
    Application.put_env(:lambdapad, :loglevel, level)

    try do
      fun.()
    after
      case previous do
        nil -> Application.delete_env(:lambdapad, :loglevel)
        level -> Application.put_env(:lambdapad, :loglevel, level)
      end
    end
  end

  describe "cwd!/1" do
    test "returns the absolute directory of an existing file" do
      file = Path.join(__DIR__, "../support/cli_project/lambdapad.exs")
      assert Cli.cwd!(file) == Path.absname(Path.dirname(file))
    end

    test "halts when the file does not exist" do
      assert catch_throw(Cli.cwd!("does-not-exist.exs")) == {:halt, 1}
    end
  end

  describe "default_file/0" do
    test "returns lambdapad.exs when index.erl is not present, index.erl otherwise" do
      dir =
        Path.join(System.tmp_dir!(), "lambdapad_cli_test_#{System.unique_integer([:positive])}")

      File.mkdir_p!(dir)
      original_cwd = File.cwd!()
      File.cd!(dir)

      on_exit(fn ->
        File.cd!(original_cwd)
        File.rm_rf!(dir)
      end)

      assert Cli.default_file() == "lambdapad.exs"

      File.write!("index.erl", "")
      assert Cli.default_file() == "index.erl"
    end
  end

  test "get_infile_options/0 declares the infile argument as optional" do
    assert Cli.get_infile_options()[:infile][:required] == false
  end

  test "get_verbosity_options/0 declares -v with a default level" do
    assert Cli.get_verbosity_options()[:verbosity][:short] == "-v"
    assert Cli.get_verbosity_options()[:verbosity][:default] == 1
  end

  test "loglevel_equal_or_greater_than?/1 compares against the configured loglevel" do
    with_loglevel(2, fn ->
      assert Cli.loglevel_equal_or_greater_than?(1)
      assert Cli.loglevel_equal_or_greater_than?(2)
      refute Cli.loglevel_equal_or_greater_than?(3)
    end)
  end

  describe "print_error/1 and done/1" do
    test "print an error message and a Done message with elapsed time" do
      assert capture_io(fn -> Cli.print_error("boom") end) =~ "error: boom"

      output = capture_io(fn -> Cli.done(System.system_time(:millisecond)) end)
      assert output =~ "Done ("
    end
  end

  describe "print_level1/1,2 and print_level1_ok/1" do
    test "prints the detailed form at loglevel 2 and the compact form below it" do
      with_loglevel(2, fn ->
        assert capture_io(fn -> Cli.print_level1("Step") end) =~ "Step:"
        assert capture_io(fn -> Cli.print_level1("Step", "detail") end) =~ "Step: "

        assert capture_io(fn -> Cli.print_level1_ok(System.system_time(:millisecond)) end) =~
                 "Done ("
      end)

      with_loglevel(1, fn ->
        assert capture_io(fn -> Cli.print_level1("Step") end) =~ "Step:\n  "
      end)
    end
  end

  describe "print_level2/1,2, print_level2_error/5, print_level2_warn/1 and print_level2_ok/0" do
    test "prints the detailed form at loglevel 2 and just a dot below it" do
      with_loglevel(2, fn ->
        assert capture_io(fn -> Cli.print_level2("Task") end) =~ "Task"
        assert capture_io(fn -> Cli.print_level2("Task", "extra") end) =~ "extra"
        assert capture_io(fn -> Cli.print_level2_ok() end) =~ "ok"
      end)

      with_loglevel(1, fn ->
        assert capture_io(fn -> Cli.print_level2("Task") end) =~ "."
      end)

      output =
        capture_io(fn -> Cli.print_level2_error("file.ex", 3, 5, "SomeError", "bad thing") end)

      assert output =~ "file.ex:3:5:"
      assert output =~ "SomeError"
      assert output =~ "bad thing"
    end

    test "print_level2_warn/1 only prints from loglevel 2 up" do
      with_loglevel(2, fn ->
        assert capture_io(fn -> Cli.print_level2_warn("careful") end) =~ "warning"
      end)

      with_loglevel(1, fn ->
        assert capture_io(fn -> Cli.print_level2_warn("careful") end) == ""
      end)
    end
  end

  describe "print_level3/1 and print_level3_multiline/1" do
    test "prints the detailed form at loglevel 3 and just a dot below it" do
      with_loglevel(3, fn ->
        assert capture_io(fn -> Cli.print_level3("detail") end) =~ "detail"

        assert capture_io(fn -> Cli.print_level3_multiline("line one\nline two") end) =~
                 "line two"
      end)

      with_loglevel(2, fn ->
        assert capture_io(fn -> Cli.print_level3("detail") end) =~ "."
        assert capture_io(fn -> Cli.print_level3_multiline("line one\nline two") end) == ""
      end)
    end
  end

  test "main/1 dispatches to the templates subcommand" do
    assert capture_io(fn -> Cli.main(["templates"]) end) =~ "Available templates"
  end
end
