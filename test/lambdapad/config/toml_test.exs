defmodule Lambdapad.Config.TomlTest do
  use ExUnit.Case
  alias Lambdapad.Config.Toml

  @workdir Path.join(__DIR__, "../../support/config")

  test "reads a map from a valid TOML file" do
    assert {:ok, %{"title" => "My Blog", "url" => "http://example.com"}} =
             Toml.read_data("blog.toml", @workdir)
  end

  test "returns an error tuple for a missing file" do
    assert {:error, message} = Toml.read_data("missing.toml", @workdir)
    assert message =~ "missing.toml"
    assert message =~ "enoent"
  end
end
