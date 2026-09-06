defmodule Lambdapad.Blog.BaseTest do
  use ExUnit.Case
  alias Lambdapad.Blog
  alias Lambdapad.Blog.Base

  describe "compile/1" do
    test "returns an error for a file with no extension" do
      assert Base.compile("no_extension_file") == {:error, :invalid_extension}
    end

    test "returns an error for an extension with no matching backend module" do
      assert Base.compile("weird.unknownext") == {:error, :module_not_found}
    end
  end

  describe "priority ordering for pages and assets" do
    setup do
      file = Path.join(__DIR__, "../../support/priority_blog.exs")
      assert {:ok, mod} = Blog.Exs.compile(file)
      {:ok, mod: mod}
    end

    test "orders pages by priority: :high first, then numeric, then :low", %{mod: mod} do
      ExUnit.CaptureIO.capture_io(:stderr, fn ->
        names = mod |> Base.get_pages(%{}) |> Enum.map(fn {name, _} -> name end)
        send(self(), {:names, names})
      end)

      assert_received {:names, names}
      assert names == ["first", "invalid_priority", "second", "third"]
    end

    test "warns and falls back to 50 for an unrecognized priority value", %{mod: mod} do
      assert ExUnit.CaptureIO.capture_io(:stderr, fn -> Base.get_pages(mod, %{}) end) =~
               "Priority don't recognized"
    end
  end

  test "assets/1 with an empty list falls back to the default general block" do
    assert Base.assets([]) == %{"general" => %{from: "assets/**", to: "site/"}}
  end
end
