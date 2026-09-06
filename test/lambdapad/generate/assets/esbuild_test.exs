defmodule Lambdapad.Generate.Assets.EsbuildTest do
  use ExUnit.Case
  alias Lambdapad.Generate.Assets.Esbuild

  # Both tests point `esbuild.path` at a real, already-existing binary so
  # `install_if_needed/1` takes its "already installed" branch and no
  # network download is ever attempted.

  test "runs the configured binary and reports success on a zero exit status" do
    data = %{esbuild: %{path: System.find_executable("echo")}}

    assert :ok = Esbuild.run(data, "app.js", System.tmp_dir!(), "app.js")
  end

  test "reports an error tuple on a non-zero exit status" do
    data = %{esbuild: %{path: System.find_executable("false")}}

    assert {:error, 1} = Esbuild.run(data, "app.js", System.tmp_dir!(), "app.js")
  end
end
