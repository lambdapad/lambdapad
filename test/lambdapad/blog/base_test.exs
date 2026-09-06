defmodule Lambdapad.Blog.BaseTest do
  use ExUnit.Case
  alias Lambdapad.Blog.Base

  describe "compile/1" do
    test "returns an error for a file with no extension" do
      assert Base.compile("no_extension_file") == {:error, :invalid_extension}
    end

    test "returns an error for an extension with no matching backend module" do
      assert Base.compile("weird.unknownext") == {:error, :module_not_found}
    end
  end
end
