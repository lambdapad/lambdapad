defmodule Lambdapad.Blog.ErlTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  alias Lambdapad.Blog.Erl

  setup_all do
    file = Path.join(__DIR__, "../../support/minimal_blog.erl")
    assert {:ok, mod} = Erl.compile(file)
    {:ok, mod: mod}
  end

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

  describe "compile/1" do
    test "halts when the file fails to compile" do
      file = Path.join(__DIR__, "../../support/broken_blog.erl")

      assert catch_throw(capture_io(fn -> Erl.compile(file) end)) == {:halt, 1}
    end
  end

  describe "defaults when widgets/1, pages/1 and assets/1 are not defined" do
    test "get_widgets/2 returns an empty map", %{mod: mod} do
      assert Erl.get_widgets(mod, %{}) == %{}
    end

    test "get_pages/2 reports the missing pages/1 function", %{mod: mod} do
      assert capture_io(fn -> Erl.get_pages(mod, %{}) end) =~
               "pages it's not defined into Erlang index."
    end

    test "get_assets/2 falls back to the general assets block", %{mod: mod} do
      assert Erl.get_assets(mod, %{}) == %{"general" => %{from: "assets/**", to: "site/"}}
    end

    test "get_checks/1 returns an empty list", %{mod: mod} do
      assert Erl.get_checks(mod) == []
    end

    test "apply_transform/2 returns the items unchanged", %{mod: mod} do
      assert Erl.apply_transform(mod, [:a, :b]) == [:a, :b]
    end
  end
end
