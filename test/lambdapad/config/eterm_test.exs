defmodule Lambdapad.Config.EtermTest do
  use ExUnit.Case
  alias Lambdapad.Config.Eterm

  @workdir Path.join(__DIR__, "../../support/config")

  test "reads a map from a valid Erlang term file" do
    assert {:ok, %{title: "My Blog", url: "http://example.com"}} =
             Eterm.read_data("blog.config", @workdir)
  end

  test "returns an error tuple for a missing file" do
    assert {:error, :enoent} = Eterm.read_data("missing.config", @workdir)
  end
end
