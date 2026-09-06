defmodule Lambdapad.Blog.ErlTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  alias Lambdapad.Blog.Erl

  describe "print_compile_errors/1" do
    test "reports the error count per file and each individual error" do
      errors = [
        {~c"index.erl", [{{3, 5}, :erl_lint, "undefined function foo/0"}]}
      ]

      output = capture_io(fn -> Erl.print_compile_errors(errors) end)

      assert output =~ "Found 1 error(s) in index.erl"
      assert output =~ "3:5:"
      assert output =~ "undefined function foo/0"
    end

    test "reports every error line for a file with more than one error" do
      errors = [
        {~c"index.erl",
         [
           {{1, 1}, :erl_lint, "first error"},
           {{2, 1}, :erl_lint, "second error"}
         ]}
      ]

      output = capture_io(fn -> Erl.print_compile_errors(errors) end)

      assert output =~ "Found 2 error(s) in index.erl"
      assert output =~ "first error"
      assert output =~ "second error"
    end
  end
end
