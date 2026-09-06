defmodule Lambdapad.ExtensionTest do
  use ExUnit.Case
  alias Lambdapad.Blog

  test "extension/1 resolves a relative path against the directory of the file that calls it" do
    file = Path.join(__DIR__, "../support/extension_project/lambdapad.exs")
    assert {:ok, mod} = Blog.Exs.compile(file)

    assert %{"greeting" => %{on: :config, run: run}} = Blog.Base.transforms(["greeting"])
    assert run.(%{}, []) == %{"greeting" => "hello from the extension"}

    _ = mod
  end
end
